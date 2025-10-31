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
    parser.add_argument("--wakeup-sound", default=str(_SOUNDS_DIR / "wake_word_triggered.flac"))
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
    _LOGGER.debug("Argumentos parseados: %s", args)

    # Load available wake words
    wake_word_dirs = [Path(ww_dir) for ww_dir in args.wake_word_dir]
    _LOGGER.debug("Directorios de wake words: %s", wake_word_dirs)
    available_wake_words: Dict[str, AvailableWakeWord] = {}

    for wake_word_dir in wake_word_dirs:
        _LOGGER.debug("Escaneando directorio: %s", wake_word_dir)
        for model_config_path in wake_word_dir.glob("*.json"):
            model_id = model_config_path.stem
            _LOGGER.debug("Archivo config encontrado: %s (id: %s)", model_config_path, model_id)
            if model_id == args.stop_model:
                # Don't show stop model as an available wake word
                _LOGGER.debug("Saltando stop model: %s", model_id)
                continue

            with open(model_config_path, "r", encoding="utf-8") as model_config_file:
                model_config = json.load(model_config_file)
                model_type = model_config["type"]
                _LOGGER.debug("Config cargada para %s: type=%s, wake_word=%s", model_id, model_type, model_config.get("wake_word"))
                available_wake_words[model_id] = AvailableWakeWord(
                    id=model_id,
                    type=WakeWordType(model_type),
                    wake_word=model_config["wake_word"],
                    trained_languages=model_config.get("trained_languages", []),
                    config_path=model_config_path,
                )

    _LOGGER.debug("Available wake words cargados: %s", list(sorted(available_wake_words.keys())))

    # Load preferences
    preferences_path = Path(args.preferences_file)
    _LOGGER.debug("Cargando preferences: %s (existe: %s)", preferences_path, preferences_path.exists())
    if preferences_path.exists():
        _LOGGER.debug("Loading preferences: %s", preferences_path)
        with open(preferences_path, "r", encoding="utf-8") as preferences_file:
            preferences_dict = json.load(preferences_file)
            _LOGGER.debug("Preferences dict: %s", preferences_dict)
            preferences = Preferences(**preferences_dict)
    else:
        _LOGGER.debug("Preferences no encontrado, usando defaults")
        preferences = Preferences()

    libtensorflowlite_c_path = _LIB_DIR / "libtensorflowlite_c.so"
    _LOGGER.debug("libtensorflowlite_c path: %s (existe: %s)", libtensorflowlite_c_path, libtensorflowlite_c_path.exists())

    # Load wake/stop models
    wake_models: Dict[str, Union[MicroWakeWord, OpenWakeWord]] = {}
    _LOGGER.debug("Active wake words de preferences: %s", preferences.active_wake_words)
    if preferences.active_wake_words:
        # Load preferred models
        for wake_word_id in preferences.active_wake_words:
            wake_word = available_wake_words.get(wake_word_id)
            if wake_word is None:
                _LOGGER.warning("Unrecognized wake word id: %s", wake_word_id)
                continue

            _LOGGER.debug("Loading wake model: %s (type: %s)", wake_word_id, type(wake_word))
            wake_models[wake_word_id] = wake_word.load(libtensorflowlite_c_path)
            _LOGGER.debug("Modelo %s cargado exitosamente", wake_word_id)

    if not wake_models:
        # Load default model
        wake_word_id = args.wake_model
        _LOGGER.debug("Usando default wake model: %s", wake_word_id)
        wake_word = available_wake_words[wake_word_id]

        _LOGGER.debug("Loading wake model: %s", wake_word_id)
        wake_models[wake_word_id] = wake_word.load(libtensorflowlite_c_path)
        _LOGGER.debug("Default modelo %s cargado", wake_word_id)

    # TODO: allow openWakeWord for "stop"
    stop_model: Optional[MicroWakeWord] = None
    _LOGGER.debug("Buscando stop model: %s", args.stop_model)
    for wake_word_dir in wake_word_dirs:
        stop_config_path = wake_word_dir / f"{args.stop_model}.json"
        _LOGGER.debug("Verificando stop config: %s (existe: %s)", stop_config_path, stop_config_path.exists())
        if not stop_config_path.exists():
            continue

        _LOGGER.debug("Loading stop model: %s", stop_config_path)
        stop_model = MicroWakeWord.from_config(
            stop_config_path, libtensorflowlite_c_path
        )
        _LOGGER.debug("Stop model cargado exitosamente")
        break

    assert stop_model is not None
    _LOGGER.debug("Todos los modelos (wake y stop) cargados")

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
    _LOGGER.debug("ServerState creado: name=%s, mac=%s, wake_models=%s", args.name, state.mac_address, list(wake_models.keys()))

    process_audio_thread = threading.Thread(
        target=process_audio, args=(state,), daemon=True
    )
    _LOGGER.debug("Iniciando process_audio thread")
    process_audio_thread.start()

    def sd_callback(indata, _frames, _time, _status):
        chunk_bytes = bytes(indata)
        _LOGGER.debug("sd_callback: frames=%s, chunk_len=%d bytes", _frames, len(chunk_bytes))
        state.audio_queue.put_nowait(chunk_bytes)

    loop = asyncio.get_running_loop()
    _LOGGER.debug("Creando server en host=%s, port=%s", args.host, args.port)
    server = await loop.create_server(
        lambda: VoiceSatelliteProtocol(state), host=args.host, port=args.port
    )
    _LOGGER.debug("Server creado")

    # Auto discovery (zeroconf, mDNS)
    discovery = HomeAssistantZeroconf(port=args.port, name=args.name)
    _LOGGER.debug("Registrando Zeroconf: port=%s, name=%s", args.port, args.name)
    await discovery.register_server()
    _LOGGER.debug("Zeroconf registrado")

    try:
        _LOGGER.debug("Opening audio input device: %s (blocksize: %s, samplerate: 16000, channels: 1)", args.audio_input_device, args.audio_input_block_size)
        with sd.RawInputStream(
            samplerate=16000,
            blocksize=args.audio_input_block_size,
            device=args.audio_input_device,
            dtype="int16",
            channels=1,
            callback=sd_callback,
        ):
            _LOGGER.debug("RawInputStream abierto exitosamente")
            async with server:
                _LOGGER.info("Server started (host=%s, port=%s)", args.host, args.port)
                await server.serve_forever()
    except KeyboardInterrupt:
        _LOGGER.info("KeyboardInterrupt recibido")
        pass
    finally:
        _LOGGER.debug("Enviando None a audio_queue para parar process_audio")
        state.audio_queue.put_nowait(None)
        _LOGGER.debug("Uniendo process_audio thread")
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

    _LOGGER.debug("process_audio iniciado")

    try:
        while True:
            audio_chunk = state.audio_queue.get()
            if audio_chunk is None:
                _LOGGER.debug("audio_chunk es None, saliendo de loop")
                break

            _LOGGER.debug("Audio chunk recibido: len=%d bytes", len(audio_chunk))

            if state.satellite is None:
                _LOGGER.debug("state.satellite es None, saltando")
                continue

            if (not wake_words) or (state.wake_words_changed and state.wake_words):
                # Update list of wake word models to process
                _LOGGER.debug("Actualizando wake_words (changed: %s, wake_words: %s)", state.wake_words_changed, bool(state.wake_words))
                state.wake_words_changed = False
                wake_words = [ww for ww in state.wake_words.values() if ww.is_active]
                _LOGGER.debug("Wake words activos: %s", [ww.id if hasattr(ww, 'id') else str(ww) for ww in wake_words])

                has_oww = False
                for wake_word in wake_words:
                    if isinstance(wake_word, OpenWakeWord):
                        has_oww = True
                        _LOGGER.debug("Detectado OpenWakeWord en wake_words")

                if micro_features is None:
                    _LOGGER.debug("Creando MicroWakeWordFeatures")
                    micro_features = MicroWakeWordFeatures(
                        libtensorflowlite_c_path=state.libtensorflowlite_c_path,
                    )
                    _LOGGER.debug("MicroWakeWordFeatures creado")

                if has_oww and (oww_features is None):
                    _LOGGER.debug("Creando OpenWakeWordFeatures")
                    oww_features = OpenWakeWordFeatures(
                        melspectrogram_model=state.oww_melspectrogram_path,
                        embedding_model=state.oww_embedding_path,
                        libtensorflowlite_c_path=state.libtensorflowlite_c_path,
                    )
                    _LOGGER.debug("OpenWakeWordFeatures creado")

            try:
                _LOGGER.debug("Llamando satellite.handle_audio con chunk len=%d", len(audio_chunk))
                state.satellite.handle_audio(audio_chunk)

                assert micro_features is not None
                _LOGGER.debug("Procesando micro_features.process_streaming")
                micro_inputs.clear()
                micro_inputs.extend(micro_features.process_streaming(audio_chunk))
                _LOGGER.debug("Micro inputs yield: %d features", len(micro_inputs))

                if has_oww:
                    assert oww_features is not None
                    _LOGGER.debug("Procesando oww_features.process_streaming")
                    oww_inputs.clear()
                    oww_inputs.extend(oww_features.process_streaming(audio_chunk))
                    _LOGGER.debug("OWW inputs yield: %d features", len(oww_inputs))

                for wake_word in wake_words:
                    _LOGGER.debug("Procesando wake_word: %s", wake_word.id if hasattr(wake_word, 'id') else str(wake_word))
                    activated = False
                    if isinstance(wake_word, MicroWakeWord):
                        _LOGGER.debug("Procesando MicroWakeWord inputs: %d", len(micro_inputs))
                        for micro_input in micro_inputs:
                            if wake_word.process_streaming(micro_input):
                                activated = True
                                _LOGGER.debug("Activación en MicroWakeWord %s", wake_word.id)
                    elif isinstance(wake_word, OpenWakeWord):
                        _LOGGER.debug("Procesando OpenWakeWord inputs: %d", len(oww_inputs))
                        for oww_input in oww_inputs:
                            for prob in wake_word.process_streaming(oww_input):
                                _LOGGER.debug("Prob en OWW: %f", prob)
                                if prob > 0.5:
                                    activated = True
                                    _LOGGER.debug("Activación en OpenWakeWord con prob >0.5")

                    if activated:
                        # Check refractory
                        now = time.monotonic()
                        _LOGGER.debug("Activación detectada, chequeando refractory: last=%s, now=%s, refractory=%s", last_active, now, state.refractory_seconds)
                        if (last_active is None) or (
                            (now - last_active) > state.refractory_seconds
                        ):
                            _LOGGER.info("WAKEUP! Llamando satellite.wakeup para %s", wake_word.id if hasattr(wake_word, 'id') else str(wake_word))
                            state.satellite.wakeup(wake_word)
                            last_active = now
                        else:
                            _LOGGER.debug("Refractory activo, ignorando")

                # Always process to keep state correct
                _LOGGER.debug("Procesando stop_word inputs: %d", len(micro_inputs))
                stopped = False
                for micro_input in micro_inputs:
                    if state.stop_word.process_streaming(micro_input):
                        stopped = True
                        _LOGGER.debug("Stop word detectado")

                if stopped and state.stop_word.is_active:
                    _LOGGER.info("STOP detectado, llamando satellite.stop")
                    state.satellite.stop()
            except Exception:
                _LOGGER.exception("Unexpected error handling audio")

    except Exception:
        _LOGGER.exception("Unexpected error processing audio")

    _LOGGER.debug("process_audio terminado")


# -----------------------------------------------------------------------------

if __name__ == "__main__":
    _LOGGER.debug("Iniciando main con asyncio.run")
    asyncio.run(main())
    _LOGGER.debug("main completado")
