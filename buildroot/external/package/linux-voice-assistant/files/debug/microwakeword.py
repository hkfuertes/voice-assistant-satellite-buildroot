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
SAMPLES_PER_CHUNK = 160
BYTES_PER_SAMPLE = 2
BYTES_PER_CHUNK = SAMPLES_PER_CHUNK * BYTES_PER_SAMPLE
SECONDS_PER_CHUNK = SAMPLES_PER_CHUNK / SAMPLES_PER_SECOND
STRIDE = 3


class MicroWakeWord(TfLiteWakeWord):
    def __init__(
        self,
        id: str,
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

        self.model_path = str(Path(tflite_model).resolve()).encode("utf-8")
        self._load_model()

        self._features: List[np.ndarray] = []
        self._probabilities: Deque[float] = deque(maxlen=self.sliding_window_size)
        self._audio_buffer = bytes()
        self._inference_count = 0

    def _load_model(self) -> None:
        self.model = self.lib.TfLiteModelCreateFromFile(self.model_path)
        self.interpreter = self.lib.TfLiteInterpreterCreate(self.model, None)
        self.lib.TfLiteInterpreterAllocateTensors(self.interpreter)

        self.input_tensor = self.lib.TfLiteInterpreterGetInputTensor(self.interpreter, 0)
        self.output_tensor = self.lib.TfLiteInterpreterGetOutputTensor(self.interpreter, 0)

        input_q = self.lib.TfLiteTensorQuantizationParams(self.input_tensor)
        output_q = self.lib.TfLiteTensorQuantizationParams(self.output_tensor)

        self.input_scale, self.input_zero_point = input_q.scale, input_q.zero_point
        self.output_scale, self.output_zero_point = output_q.scale, output_q.zero_point
        
        _LOGGER.debug(f"[{self.id}] Model loaded. Input scale={self.input_scale:.4f}, zp={self.input_zero_point}. Output scale={self.output_scale:.4f}, zp={self.output_zero_point}")

    @staticmethod
    def from_config(
        config_path: Union[str, Path],
        libtensorflowlite_c_path: Union[str, Path],
    ) -> "MicroWakeWord":
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
        self._features.append(features)

        if len(self._features) < STRIDE:
            return False

        pre_quant_features = np.concatenate(self._features, axis=1)
        quant_features = np.round(
            pre_quant_features / self.input_scale + self.input_zero_point
        ).astype(np.uint8)

        self._features.clear()

        quant_ptr = quant_features.ctypes.data_as(ctypes.c_void_p)
        self.lib.TfLiteTensorCopyFromBuffer(self.input_tensor, quant_ptr, quant_features.nbytes)

        self.lib.TfLiteInterpreterInvoke(self.interpreter)
        self._inference_count += 1

        output_bytes = self.lib.TfLiteTensorByteSize(self.output_tensor)
        output_data = np.empty(output_bytes, dtype=np.uint8)
        self.lib.TfLiteTensorCopyToBuffer(
            self.output_tensor,
            output_data.ctypes.data_as(ctypes.c_void_p),
            output_bytes,
        )

        result = (output_data.astype(np.float32) - self.output_zero_point) * self.output_scale
        self._probabilities.append(result.item())

        if self._inference_count % 20 == 0:
            _LOGGER.debug(
                f"[{self.id}] Inference #{self._inference_count}: "
                f"Pre-Quant mean={pre_quant_features.mean():.2f}, "
                f"Quant mean={quant_features.mean():.2f}, "
                f"Raw Output={output_data[0]}, "
                f"Prob={result.item():.4f}, "
                f"Window Mean={statistics.mean(self._probabilities):.4f} / {self.probability_cutoff}"
            )

        if len(self._probabilities) < self.sliding_window_size:
            return False

        if statistics.mean(self._probabilities) > self.probability_cutoff:
            _LOGGER.info(f"[{self.id}] ACTIVATION! Window mean {statistics.mean(self._probabilities):.4f} > {self.probability_cutoff}")
            self._probabilities.clear()
            return True

        return False

# -----------------------------------------------------------------------------

class MicroWakeWordFeatures(TfLiteWakeWord):
    def __init__(self, libtensorflowlite_c_path: Union[str, Path]) -> None:
        TfLiteWakeWord.__init__(self, libtensorflowlite_c_path)
        self._audio_buffer = bytes()
        self._frontend = MicroFrontend()
        self._feature_count = 0

    def process_streaming(self, audio_bytes: bytes) -> Iterable[np.ndarray]:
        self._audio_buffer += audio_bytes
        if len(self._audio_buffer) < BYTES_PER_CHUNK:
            return

        audio_buffer_idx = 0
        while (audio_buffer_idx + BYTES_PER_CHUNK) <= len(self._audio_buffer):
            chunk_bytes = self._audio_buffer[audio_buffer_idx : audio_buffer_idx + BYTES_PER_CHUNK]
            frontend_result = self._frontend.ProcessSamples(chunk_bytes)
            audio_buffer_idx += frontend_result.samples_read * BYTES_PER_SAMPLE

            if not frontend_result.features:
                continue
            
            self._feature_count += 1
            features_array = np.array(frontend_result.features)
            
            if self._feature_count % 50 == 0:
                _LOGGER.debug(
                    f"[Features] Generated feature #{self._feature_count}: "
                    f"shape={features_array.shape}, min={features_array.min():.2f}, "
                    f"max={features_array.max():.2f}, mean={features_array.mean():.2f}"
                )

            yield features_array.reshape((1, 1, len(frontend_result.features)))

        self._audio_buffer = self._audio_buffer[audio_buffer_idx:]
