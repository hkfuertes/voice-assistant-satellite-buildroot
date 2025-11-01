import ctypes
import json
import logging
import statistics
from collections import deque
from collections.abc import Iterable
from pathlib import Path
from typing import Deque, List, Union

import numpy as np
from pymicro_features import MicroFrontend

from .wakeword import TfLiteWakeWord

_LOGGER = logging.getLogger(__name__)

SAMPLES_PER_SECOND = 16000
SAMPLES_PER_CHUNK = 160  # 10ms
BYTES_PER_SAMPLE = 2  # 16-bit
BYTES_PER_CHUNK = SAMPLES_PER_CHUNK * BYTES_PER_SAMPLE
SECONDS_PER_CHUNK = SAMPLES_PER_CHUNK / SAMPLES_PER_SECOND
STRIDE = 3


class MicroWakeWord(TfLiteWakeWord):
    def __init__(
        self,
        id: str,  # pylint: disable=redefined-builtin
        wake_word: str,
        tflite_model: Union[str, Path],
        probability_cutoff: float,
        sliding_window_size: int,
        trained_languages: List[str],
        libtensorflowlite_c_path: Union[str, Path],
    ) -> None:
        TfLiteWakeWord.__init__(self, libtensorflowlite_c_path)

        self.id = id
        self.wake_word = wake_word
        self.tflite_model = tflite_model
        self.probability_cutoff = probability_cutoff
        self.sliding_window_size = sliding_window_size
        self.trained_languages = trained_languages

        self.is_active = True

        # Load the model and create interpreter
        self.model_path = str(Path(tflite_model).resolve()).encode("utf-8")
        _LOGGER.debug(
            "[MWW:init] id=%s wake='%s' model=%s cutoff=%.3f window=%d langs=%s",
            self.id,
            self.wake_word,
            self.model_path.decode('utf-8', errors='ignore'),
            self.probability_cutoff,
            self.sliding_window_size,
            self.trained_languages,
        )
        self._load_model()

        self._features: List[np.ndarray] = []
        self._probabilities: Deque[float] = deque(maxlen=self.sliding_window_size)
        self._audio_buffer = bytes()

    def _load_model(self) -> None:
        self.model = self.lib.TfLiteModelCreateFromFile(self.model_path)
        self.interpreter = self.lib.TfLiteInterpreterCreate(self.model, None)
        self.lib.TfLiteInterpreterAllocateTensors(self.interpreter)

        # Access input and output tensor
        self.input_tensor = self.lib.TfLiteInterpreterGetInputTensor(
            self.interpreter, 0
        )
        self.output_tensor = self.lib.TfLiteInterpreterGetOutputTensor(
            self.interpreter, 0
        )

        # Get quantization parameters
        input_q = self.lib.TfLiteTensorQuantizationParams(self.input_tensor)
        output_q = self.lib.TfLiteTensorQuantizationParams(self.output_tensor)

        self.input_scale, self.input_zero_point = input_q.scale, input_q.zero_point
        self.output_scale, self.output_zero_point = output_q.scale, output_q.zero_point

        in_bytes = self.lib.TfLiteTensorByteSize(self.input_tensor)
        out_bytes = self.lib.TfLiteTensorByteSize(self.output_tensor)
        _LOGGER.debug(
            "[MWW:load] q_in scale=%.6g zero=%d | q_out scale=%.6g zero=%d | io_bytes in=%d out=%d",
            self.input_scale, self.input_zero_point,
            self.output_scale, self.output_zero_point,
            in_bytes, out_bytes
        )

    @staticmethod
    def from_config(
        config_path: Union[str, Path],
        libtensorflowlite_c_path: Union[str, Path],
    ) -> "MicroWakeWord":
        """Load a microWakeWord model from a JSON config file.

        Parameters
        ----------
        config_path: str or Path
            Path to JSON configuration file
        """
        config_path = Path(config_path)
        with open(config_path, "r", encoding="utf-8") as config_file:
            config = json.load(config_file)

        micro_config = config["micro"]

        return MicroWakeWord(
            id=Path(config["model"]).stem,
            wake_word=config["wake_word"],
            tflite_model=config_path.parent / config["model"],
            probability_cutoff=micro_config["probability_cutoff"],
            sliding_window_size=micro_config["sliding_window_size"],
            trained_languages=micro_config.get("trained_languages", []),
            libtensorflowlite_c_path=libtensorflowlite_c_path,
        )

    def process_streaming(self, features: np.ndarray) -> bool:
        # Saneamiento y logs de features de entrada
        try:
            f = features.astype(np.float32, copy=False)
            has_nan = bool(np.isnan(f).any())
            has_inf = bool(np.isinf(f).any())
            fmin = float(np.min(f)) if f.size else float("nan")
            fmax = float(np.max(f)) if f.size else float("nan")
            fmean = float(np.mean(f)) if f.size else float("nan")
            _LOGGER.debug(
                "[MWW:feat] in shape=%s len=%d min=%.3f max=%.3f mean=%.3f nan=%s inf=%s",
                tuple(f.shape), f.size, fmin, fmax, fmean, has_nan, has_inf
            )
        except Exception as e:
            _LOGGER.debug("[MWW:feat] feature log error: %r", e)

        self._features.append(features)

        if len(self._features) < STRIDE:
            _LOGGER.debug("[MWW] waiting for stride: %d/%d", len(self._features), STRIDE)
            return False

        # Allocate and quantize input data
        concat = np.concatenate(self._features, axis=1)
        self._features.clear()
        _LOGGER.debug("[MWW] concat shape=%s", tuple(concat.shape))

        quant_features = np.round(
            concat / self.input_scale + self.input_zero_point
        ).astype(np.uint8)

        try:
            qmin = int(quant_features.min()) if quant_features.size else -1
            qmax = int(quant_features.max()) if quant_features.size else -1
            _LOGGER.debug("[MWW:q] qmin=%d qmax=%d nbytes=%d", qmin, qmax, quant_features.nbytes)
        except Exception as e:
            _LOGGER.debug("[MWW:q] stats error: %r", e)

        # Stride instead of rolling
        quant_ptr = quant_features.ctypes.data_as(ctypes.c_void_p)
        self.lib.TfLiteTensorCopyFromBuffer(
            self.input_tensor, quant_ptr, quant_features.nbytes
        )

        # Run inference
        self.lib.TfLiteInterpreterInvoke(self.interpreter)

        # Read output
        output_bytes = self.lib.TfLiteTensorByteSize(self.output_tensor)
        output_data = np.empty(output_bytes, dtype=np.uint8)
        self.lib.TfLiteTensorCopyToBuffer(
            self.output_tensor,
            output_data.ctypes.data_as(ctypes.c_void_p),
            output_bytes,
        )

        # Dequantize output
        result = (
            output_data.astype(np.float32) - self.output_zero_point
        ) * self.output_scale
        prob = float(result.item()) if result.size else float("nan")
        self._probabilities.append(prob)

        avgp = statistics.mean(self._probabilities) if len(self._probabilities) else float("nan")
        _LOGGER.debug("[MWW:out] prob=%.3f avg(%d)=%.3f", prob, self.sliding_window_size, avgp)

        if len(self._probabilities) < self.sliding_window_size:
            # Not enough probabilities
            return False

        if avgp > self.probability_cutoff:
            _LOGGER.debug("[MWW:TRIGGER] avg=%.3f > cutoff=%.3f", avgp, self.probability_cutoff)
            return True

        return False


# -----------------------------------------------------------------------------


class MicroWakeWordFeatures(TfLiteWakeWord):
    def __init__(
        self,
        libtensorflowlite_c_path: Union[str, Path],
    ) -> None:
        TfLiteWakeWord.__init__(self, libtensorflowlite_c_path)

        self._audio_buffer = bytes()
        self._frontend = MicroFrontend()
        _LOGGER.debug("[MWWF:init] MicroFrontend creado")

    def process_streaming(self, audio_bytes: bytes) -> Iterable[np.ndarray]:
        self._audio_buffer += audio_bytes
        _LOGGER.debug("[MWWF:audio] buf_len=%d chunk_in=%d", len(self._audio_buffer), len(audio_bytes))

        if len(self._audio_buffer) < BYTES_PER_CHUNK:
            # Not enough audio to get features
            return

        audio_buffer_idx = 0
        while (audio_buffer_idx + BYTES_PER_CHUNK) <= len(self._audio_buffer):
            # Process chunk
            chunk_bytes = self._audio_buffer[
                audio_buffer_idx : audio_buffer_idx + BYTES_PER_CHUNK
            ]

            # Log del PCM de entrada (RMS/mean) para detectar DC o clipping
            try:
                pcm = np.frombuffer(chunk_bytes, dtype="<i2")
                rms = float(np.sqrt(np.mean(pcm.astype(np.float32) ** 2)))
                mean = float(np.mean(pcm))
                _LOGGER.debug("[MWWF:pcm] samples=%d rms=%.1f mean=%.1f", pcm.size, rms, mean)
            except Exception as e:
                _LOGGER.debug("[MWWF:pcm] stats error: %r", e)

            frontend_result = self._frontend.ProcessSamples(chunk_bytes)
            audio_buffer_idx += frontend_result.samples_read * BYTES_PER_SAMPLE

            if not frontend_result.features:
                # Not enough audio for a full window
                _LOGGER.debug("[MWWF:feat] insuficiente: samples_read=%d", frontend_result.samples_read)
                continue

            feats = np.array(frontend_result.features).reshape(
                (1, 1, len(frontend_result.features))
            )

            try:
                f = feats.reshape(-1).astype(np.float32)
                _LOGGER.debug(
                    "[MWWF:feat] len=%d min=%.3f max=%.3f mean=%.3f",
                    f.size, float(np.min(f)), float(np.max(f)), float(np.mean(f))
                )
            except Exception as e:
                _LOGGER.debug("[MWWF:feat] stats error: %r", e)

            yield feats

        # Remove processed audio
        self._audio_buffer = self._audio_buffer[audio_buffer_idx:]
