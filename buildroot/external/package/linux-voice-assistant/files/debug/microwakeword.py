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
        self._load_model()

        self._features: List[np.ndarray] = []
        self._probabilities: Deque[float] = deque(maxlen=self.sliding_window_size)
        self._audio_buffer = bytes()
        
        # DEBUG COUNTERS
        self._debug_chunk_count = 0
        self._debug_feature_count = 0
        self._debug_inference_count = 0

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
        
        # DEBUG: Log tensor details AQUÍ
        self._log_tensor_details()
        
        _LOGGER.debug(
            "[MWW:model] id=%s input_scale=%.6f input_zp=%d output_scale=%.6f output_zp=%d cutoff=%.3f",
            self.id, self.input_scale, self.input_zero_point,
            self.output_scale, self.output_zero_point, self.probability_cutoff
        )

    def _log_tensor_details(self):
        """Log detailed tensor information for debugging."""
        # Input tensor details
        input_dims = []
        try:
            input_num_dims = self.lib.TfLiteTensorNumDims(self.input_tensor)
            for i in range(input_num_dims):
                dim = self.lib.TfLiteTensorDim(self.input_tensor, i)
                input_dims.append(dim)
        except Exception as e:
            _LOGGER.debug("[MWW:tensor_info] Error getting input dims: %s", e)
        
        input_bytes = self.lib.TfLiteTensorByteSize(self.input_tensor)
        input_type_c = self.lib.TfLiteTensorType(self.input_tensor)
        
        # Output tensor details
        output_dims = []
        try:
            output_num_dims = self.lib.TfLiteTensorNumDims(self.output_tensor)
            for i in range(output_num_dims):
                dim = self.lib.TfLiteTensorDim(self.output_tensor, i)
                output_dims.append(dim)
        except Exception as e:
            _LOGGER.debug("[MWW:tensor_info] Error getting output dims: %s", e)
        
        output_bytes = self.lib.TfLiteTensorByteSize(self.output_tensor)
        output_type_c = self.lib.TfLiteTensorType(self.output_tensor)
        
        _LOGGER.debug(
            "[MWW:tensor_info] input_dims=%s input_bytes=%d input_type=%d | output_dims=%s output_bytes=%d output_type=%d",
            input_dims, input_bytes, input_type_c, output_dims, output_bytes, output_type_c
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
        self._features.append(features)
        self._debug_feature_count += 1
        
        # DEBUG: Log incoming features
        _LOGGER.debug(
            "[MWW:feat:in] #%d shape=%s min=%.3f max=%.3f mean=%.3f",
            self._debug_feature_count, features.shape,
            np.min(features), np.max(features), np.mean(features)
        )

        if len(self._features) < STRIDE:
            # Not enough windows
            _LOGGER.debug("[MWW:stride] waiting %d/%d", len(self._features), STRIDE)
            return False

        # Concatenate features
        concat_features = np.concatenate(self._features, axis=1)
        _LOGGER.debug(
            "[MWW:concat] shape=%s min=%.3f max=%.3f mean=%.3f",
            concat_features.shape, np.min(concat_features),
            np.max(concat_features), np.mean(concat_features)
        )

        # Allocate and quantize input data
        pre_quant = np.concatenate(self._features, axis=1) / self.input_scale + self.input_zero_point
        _LOGGER.debug(
            "[MWW:prequant] min=%.3f max=%.3f mean=%.3f",
            np.min(pre_quant), np.max(pre_quant), np.mean(pre_quant)
        )
        
        quant_features = np.round(pre_quant).astype(np.uint8)
        _LOGGER.debug(
            "[MWW:quant] shape=%s bytes=%d min=%d max=%d mean=%.1f",
            quant_features.shape, quant_features.nbytes,
            np.min(quant_features), np.max(quant_features), np.mean(quant_features)
        )

        # Stride instead of rolling
        self._features.clear()

        # Set tensor
        quant_ptr = quant_features.ctypes.data_as(ctypes.c_void_p)
        self.lib.TfLiteTensorCopyFromBuffer(
            self.input_tensor, quant_ptr, quant_features.nbytes
        )
        
        _LOGGER.debug("[MWW:tensor] copied %d bytes to input tensor", quant_features.nbytes)

        # Run inference
        self._debug_inference_count += 1
        self.lib.TfLiteInterpreterInvoke(self.interpreter)
        _LOGGER.debug("[MWW:infer] #%d inference executed", self._debug_inference_count)

        # Read output
        output_bytes = self.lib.TfLiteTensorByteSize(self.output_tensor)
        output_data = np.empty(output_bytes, dtype=np.uint8)
        self.lib.TfLiteTensorCopyToBuffer(
            self.output_tensor,
            output_data.ctypes.data_as(ctypes.c_void_p),
            output_bytes,
        )

        # Dequantize output
        pre_dequant = output_data.astype(np.float32) - self.output_zero_point
        result = pre_dequant * self.output_scale
        
        _LOGGER.debug(
            "[MWW:output] raw=%s predequant_min=%.3f predequant_max=%.3f dequant=%.6f",
            output_data[:5] if len(output_data) > 5 else output_data,
            np.min(pre_dequant), np.max(pre_dequant), result.item()
        )

        self._probabilities.append(result.item())
        
        _LOGGER.debug(
            "[MWW:prob] current=%.6f queue_len=%d avg=%.6f cutoff=%.3f",
            result.item(), len(self._probabilities),
            statistics.mean(self._probabilities) if self._probabilities else 0,
            self.probability_cutoff
        )

        if len(self._probabilities) < self.sliding_window_size:
            # Not enough probabilities
            _LOGGER.debug("[MWW:probwait] waiting for %d probabilities, have %d",
                         self.sliding_window_size, len(self._probabilities))
            return False

        avg_prob = statistics.mean(self._probabilities)
        triggered = avg_prob > self.probability_cutoff
        
        _LOGGER.debug(
            "[MWW:decision] avg_prob=%.6f cutoff=%.3f TRIGGERED=%s",
            avg_prob, self.probability_cutoff, triggered
        )

        return triggered


# -----------------------------------------------------------------------------


class MicroWakeWordFeatures(TfLiteWakeWord):
    def __init__(
        self,
        libtensorflowlite_c_path: Union[str, Path],
    ) -> None:
        TfLiteWakeWord.__init__(self, libtensorflowlite_c_path)

        self._audio_buffer = bytes()
        self._frontend = MicroFrontend()
        
        # DEBUG
        self._debug_chunk_count = 0
        self._debug_window_count = 0

    def process_streaming(self, audio_bytes: bytes) -> Iterable[np.ndarray]:
        self._debug_chunk_count += 1
        
        _LOGGER.debug(
            "[MWF:audio] chunk#%d bytes_in=%d buffer_before=%d",
            self._debug_chunk_count, len(audio_bytes), len(self._audio_buffer)
        )
        
        self._audio_buffer += audio_bytes

        if len(self._audio_buffer) < BYTES_PER_CHUNK:
            # Not enough audio to get features
            _LOGGER.debug("[MWF:wait] need %d bytes, have %d", BYTES_PER_CHUNK, len(self._audio_buffer))
            return

        audio_buffer_idx = 0
        while (audio_buffer_idx + BYTES_PER_CHUNK) <= len(self._audio_buffer):
            # Process chunk
            chunk_bytes = self._audio_buffer[
                audio_buffer_idx : audio_buffer_idx + BYTES_PER_CHUNK
            ]
            
            # Convert bytes to int16 for debugging
            chunk_int16 = np.frombuffer(chunk_bytes, dtype=np.int16)
            
            _LOGGER.debug(
                "[MWF:chunk] idx=%d bytes=%d int16_min=%d int16_max=%d int16_mean=%.1f int16_rms=%.1f",
                audio_buffer_idx, len(chunk_bytes),
                np.min(chunk_int16), np.max(chunk_int16),
                np.mean(chunk_int16), np.sqrt(np.mean(chunk_int16**2))
            )
            
            frontend_result = self._frontend.ProcessSamples(chunk_bytes)
            audio_buffer_idx += frontend_result.samples_read * BYTES_PER_SAMPLE

            if not frontend_result.features:
                # Not enough audio for a full window
                _LOGGER.debug(
                    "[MWF:nofeatures] samples_read=%d (no features yet)",
                    frontend_result.samples_read
                )
                continue

            self._debug_window_count += 1
            features_array = np.array(frontend_result.features).reshape(
                (1, 1, len(frontend_result.features))
            )
            
            _LOGGER.debug(
                "[MWF:features] window#%d len=%d min=%.3f max=%.3f mean=%.3f",
                self._debug_window_count, len(frontend_result.features),
                np.min(features_array), np.max(features_array), np.mean(features_array)
            )
            
            yield features_array

        # Remove processed audio
        self._audio_buffer = self._audio_buffer[audio_buffer_idx:]
        
        _LOGGER.debug("[MWF:buffer] removed %d bytes, %d remaining", audio_buffer_idx, len(self._audio_buffer))
