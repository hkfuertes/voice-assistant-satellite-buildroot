#!/usr/bin/env python3
import argparse
import asyncio
import json
import logging
import threading
import time
from pathlib import Path
from queue import Queue
from typing import Dict, List, Optional, Union

import numpy as np
import sounddevice as sd

from .microwakeword import MicroWakeWord, MicroWakeWordFeatures
from .models import AvailableWakeWord, Preferences, ServerState, WakeWordType
from .mpv_player import MpvMediaPlayer
from .openwakeword import OpenWakeWord, OpenWakeWordFeatures
from .satellite import VoiceSatelliteProtocol
from .util import get_mac, is_arm
from .zeroconf import HomeAssistantZeroconf

_LOGGER = logging.getLogger(__name__)
_MODULE_DIR = Path(__file__).parent
_REPO_DIR = _MODULE_DIR.parent
_WAKEWORDS_DIR = _REPO_DIR / "wakewords"
_OWW_DIR = _WAKEWORDS_DIR / "openWakeWord"
_SOUNDS_DIR = _REPO_DIR / "sounds"

if is_arm():
    _LIB_DIR = _REPO_DIR / "lib" / "linux_arm64"
else:
    _LIB_DIR = _REPO_DIR / "lib" / "linux_amd64"


# -----------------------------------------------------------------------------


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", required=True)
    parser.add_argument(
        "--audio-input-device",
        default="default",
        help="sounddevice name for input device",
    )
    parser.add_argument("--audio-input-block-size", type=int, default=1024)
    parser.add_argument("--audio-output-device", help="mpv name for output device")
    parser.add_argument(
        "--wake-word-dir",
        default=[_WAKEWORDS_DIR],
        action="append",
        help="Directory with wake word models (.tflite) and configs (.json)",
    )
    parser.add_argument(
        "--wake-model", default="okay_nabu", help="Id of active wake model"
    )
    parser.add_argument("--stop-model", default="stop", help="Id of stop model")
    parser.add_argument(
        "--refractory-seconds",
        default=2.0,
        type=float,
        help="Seconds before wake word can be activated again",
    )
    #
    parser.add_argument(
        "--oww-melspectrogram-model",
        default=_OWW_DIR / "melspectrogram.tflite",
        help="Path to openWakeWord melspectrogram model",
    )
    parser.add_argument(
        "--oww-embedding-model",
        default=_OWW_DIR / "embedding_model.tflite",
        help="Path to openWakeWord embedding model",
    )
    #
    parser.add_argument(
        "--wakeup-sound", default=str(_SOUNDS_DIR / "wake_word_triggered.flac")
    )
    parser.add_argument(
        "--timer-finished-sound", default=str(_SOUNDS_DIR / "timer_finished.flac")
    )
    #
    parser.add_argument("--preferences-file", default=_REPO_DIR / "preferences.json")
    #
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="Address for ESPHome server (default: 0.0.0.0)",
    )
    parser.add_argument(
        "--port", type=int, default=6053, help="Port for ESPHome server (default: 6053)"
    )
    parser.add_argument(
        "--debug", action="store_true", help="Print DEBUG messages to console"
    )
    args = parser.parse_args()

    logging.basicConfig(level=logging.DEBUG if args.debug else logging.INFO)
    _LOGGER.debug(args)

    # Load available wake words
    wake_word_dirs = [Path(ww_dir) for ww_dir in args.wake_word_dir]
    available_wake_words: Dict[str, AvailableWakeWord] = {}

    for wake_word_dir in wake_word_dirs:
        for model_config_path in wake_word_dir.glob("*.json"):
            model_id = model_config_path.stem
            if model_id == args.stop_model:
                # Don't show stop model as an available wake word
                continue

            with open(model_config_path, "r", encoding="utf-8") as model_config_file:
                model_config = json.load(model_config_file)
                model_type = model_config["type"]
                available_wake_words[model_id] = AvailableWakeWord(
                    id=model_id,
                    type=WakeWordType(model_type),
                    wake_word=model_config["wake_word"],
                    trained_languages=model_config.get("trained_languages", []),
                    config_path=model_config_path,
                )

    _LOGGER.debug("Available wake words: %s", list(sorted(available_wake_words.keys())))

    # Load preferences
    preferences_path = Path(args.preferences_file)
    if preferences_path.exists():
        _LOGGER.debug("Loading preferences: %s", preferences_path)
        with open(preferences_path, "r", encoding="utf-8") as preferences_file:
            preferences_dict = json.load(preferences_file)
            preferences = Preferences(**preferences_dict)
    else:
        preferences = Preferences()

    libtensorflowlite_c_path = _LIB_DIR / "libtensorflowlite_c.so"
    _LOGGER.debug("libtensorflowlite_c path: %s", libtensorflowlite_c_path)

    # Load wake/stop models
    wake_models: Dict[str, Union[MicroWakeWord, OpenWakeWord]] = {}
    if preferences.active_wake_words:
        # Load preferred models
        for wake_word_id in preferences.active_wake_words:
            wake_word = available_wake_words.get(wake_word_id)
            if wake_word is None:
                _LOGGER.warning("Unrecognized wake word id: %s", wake_word_id)
                continue

            _LOGGER.debug("Loading wake model: %s", wake_word_id)
            wake_models[wake_word_id] = wake_word.load(libtensorflowlite_c_path)

    if not wake_models:
        # Load default model
        wake_word_id = args.wake_model
        wake_word = available_wake_words[wake_word_id]

        _LOGGER.debug("Loading wake model: %s", wake_word_id)
        wake_models[wake_word_id] = wake_word.load(libtensorflowlite_c_path)

    # TODO: allow openWakeWord for "stop"
    stop_model: Optional[MicroWakeWord] = None
    for wake_word_dir in wake_word_dirs:
        stop_config_path = wake_word_dir / f"{args.stop_model}.json"
        if not stop_config_path.exists():
            continue

        _LOGGER.debug("Loading stop model: %s", stop_config_path)
        stop_model = MicroWakeWord.from_config(
            stop_config_path, libtensorflowlite_c_path
        )
        break

    assert stop_model is not None

    state = ServerState(
        name=args.name,
        mac_address=get_mac(),
        audio_queue=Queue(),
        entities=[],
        available_wake_words=available_wake_words,
        wake_words=wake_models,
        stop_word=stop_model,
        music_player=MpvMediaPlayer(device=args.audio_output_device),
        tts_player=MpvMediaPlayer(device=args.audio_output_device),
        wakeup_sound=args.wakeup_sound,
        timer_finished_sound=args.timer_finished_sound,
        preferences=preferences,
        preferences_path=preferences_path,
        libtensorflowlite_c_path=libtensorflowlite_c_path,
        oww_melspectrogram_path=Path(args.oww_melspectrogram_model),
        oww_embedding_path=Path(args.oww_embedding_model),
        refractory_seconds=args.refractory_seconds,
    )

    process_audio_thread = threading.Thread(
        target=process_audio, args=(state,), daemon=True
    )
    process_audio_thread.start()

    blk_counter = 0

    def sd_callback(indata, _frames, _time, _status):
        nonlocal blk_counter
        if _status:
            _LOGGER.debug("[SD] status=%s", _status)
        blk_counter += 1
        _LOGGER.debug("[SD] blk=%d bytes=%d", blk_counter, len(indata))
        state.audio_queue.put_nowait(bytes(indata))

    loop = asyncio.get_running_loop()
    server = await loop.create_server(
        lambda: VoiceSatelliteProtocol(state), host=args.host, port=args.port
    )

    # Auto discovery (zeroconf, mDNS)
    discovery = HomeAssistantZeroconf(port=args.port, name=args.name)
    await discovery.register_server()

    try:
        _LOGGER.debug("Opening audio input device: %s", args.audio_input_device)
        with sd.RawInputStream(
            samplerate=16000,
            blocksize=args.audio_input_block_size,
            device=args.audio_input_device,
            dtype="int16",
            channels=1,
            callback=sd_callback,
        ):
            async with server:
                _LOGGER.info("Server started (host=%s, port=%s)", args.host, args.port)
                await server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        state.audio_queue.put_nowait(None)
        process_audio_thread.join()

    _LOGGER.debug("Server stopped")


# -----------------------------------------------------------------------------


def process_audio(state: ServerState):
    """Process audio chunks from the microphone."""

    wake_words: List[Union[MicroWakeWord, OpenWakeWord]] = []
    micro_features: Optional[MicroWakeWordFeatures] = None
    micro_inputs: List[np.ndarray] = []

    oww_features: Optional[OpenWakeWordFeatures] = None
    oww_inputs: List[np.ndarray] = []
    has_oww = False

    last_active: Optional[float] = None
    proc_blk = 0

    try:
        while True:
            audio_chunk = state.audio_queue.get()
            if audio_chunk is None:
                break

            proc_blk += 1
            _LOGGER.debug("[PROC] blk=%d bytes=%d queue=%d", proc_blk, len(audio_chunk), state.audio_queue.qsize())

            if state.satellite is None:
                continue

            if (not wake_words) or (state.wake_words_changed and state.wake_words):
                # Update list of wake word models to process
                state.wake_words_changed = False
                wake_words = [ww for ww in state.wake_words.values() if ww.is_active]
                _LOGGER.debug("[PROC] active wake models=%d", len(wake_words))

                has_oww = any(isinstance(w, OpenWakeWord) for w in wake_words)

                if micro_features is None:
                    micro_features = MicroWakeWordFeatures(
                        libtensorflowlite_c_path=state.libtensorflowlite_c_path,
                    )
                    _LOGGER.debug("[PROC] MicroWakeWordFeatures inicializado")

                if has_oww and (oww_features is None):
                    oww_features = OpenWakeWordFeatures(
                        melspectrogram_model=state.oww_melspectrogram_path,
                        embedding_model=state.oww_embedding_path,
                        libtensorflowlite_c_path=state.libtensorflowlite_c_path,
                    )
                    _LOGGER.debug("[PROC] OpenWakeWordFeatures inicializado")

            try:
                state.satellite.handle_audio(audio_chunk)

                assert micro_features is not None
                micro_inputs.clear()
                micro_inputs.extend(micro_features.process_streaming(audio_chunk))
                _LOGGER.debug("[PROC] micro_inputs=%d", len(micro_inputs))

                if has_oww:
                    assert oww_features is not None
                    oww_inputs.clear()
                    oww_inputs.extend(oww_features.process_streaming(audio_chunk))
                    _LOGGER.debug("[PROC] oww_inputs=%d", len(oww_inputs))

                for wake_word in wake_words:
                    activated = False
                    if isinstance(wake_word, MicroWakeWord):
                        for micro_input in micro_inputs:
                            if wake_word.process_streaming(micro_input):
                                activated = True
                        if wake_word._probabilities:
                            _LOGGER.debug(
                                "[PROC:MWW] last_prob=%.3f avg=%.3f win=%d",
                                wake_word._probabilities[-1],
                                float(np.mean(wake_word._probabilities)),
                                wake_word.sliding_window_size,
                            )
                    elif isinstance(wake_word, OpenWakeWord):
                        for oww_input in oww_inputs:
                            for prob in wake_word.process_streaming(oww_input):
                                _LOGGER.debug("[PROC:OWW] prob=%.3f", prob)
                                if prob > 0.5:
                                    activated = True

                    if activated:
                        # Check refractory
                        now = time.monotonic()
                        if (last_active is None) or (
                            (now - last_active) > state.refractory_seconds
                        ):
                            _LOGGER.debug("[PROC] WAKE! model=%s", getattr(wake_word, "id", "oww"))
                            state.satellite.wakeup(wake_word)
                            last_active = now
                        else:
                            _LOGGER.debug("[PROC] refractory (%.2fs left)", state.refractory_seconds - (now - last_active))

                # Always process to keep state correct
                stopped = False
                for micro_input in micro_inputs:
                    if state.stop_word.process_streaming(micro_input):
                        stopped = True

                if stopped and state.stop_word.is_active:
                    _LOGGER.debug("[PROC] STOP word activado")
                    state.satellite.stop()
            except Exception:
                _LOGGER.exception("Unexpected error handling audio")

    except Exception:
        _LOGGER.exception("Unexpected error processing audio")


# -----------------------------------------------------------------------------

if __name__ == "__main__":
    asyncio.run(main())
