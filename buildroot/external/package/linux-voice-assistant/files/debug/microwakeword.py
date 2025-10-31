import ctypes
import json
import statistics
import time
import logging
from collections import deque
from collections.abc import Iterable
from pathlib import Path
from typing import Deque, List, Union

import numpy as np
from pymicro_features import MicroFrontend

from .wakeword import TfLiteWakeWord

# Config logging (usa env DEBUG para verbose)
logging.basicConfig(
    level=logging.DEBUG if os.getenv('DEBUG', '0') == '1' else logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s'
)
logger = logging.getLogger(__name__)

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
        super().__init__(libtensorflowlite_c_path)  # TfLiteWakeWord.__init__(self, libtensorflowlite_c_path)

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
        
        logger.debug(f"MicroWakeWord init completado: id={id}, wake_word={wake_word}, model={tflite_model}, cutoff={probability_cutoff}, window={sliding_window_size}, langs={trained_languages}")

    def _load_model(self) -> None:
        start_time = time.time()
        logger.info(f"Cargando modelo TFLite: {self.model_path.decode('utf-8')}")
        try:
            self.model = self.lib.TfLiteModelCreateFromFile(self.model_path)
            if self.model is None:
                raise RuntimeError(f"Fallo en TfLiteModelCreateFromFile: Modelo inválido o no encontrado ({self.model_path.decode('utf-8')})")
            logger.debug(f"Modelo TFLite creado exitosamente")

            self.interpreter = self.lib.TfLiteInterpreterCreate(self.model, None)
            if self.interpreter is None:
                raise RuntimeError("Fallo en TfLiteInterpreterCreate")
            logger.debug(f"Interpreter creado")

            self.lib.TfLiteInterpreterAllocateTensors(self.interpreter)
            logger.debug(f"Tensores asignados")

            # Access input and output tensor
            self.input_tensor = self.lib.TfLiteInterpreterGetInputTensor(self.interpreter, 0)
            self.output_tensor = self.lib.TfLiteInterpreterGetOutputTensor(self.interpreter, 0)
            if self.input_tensor is None or self.output_tensor is None:
                raise RuntimeError("Tensores input/output no válidos")

            # Get tensor details for debug
            input_details = self.lib.TfLiteTensorNumDims(self.input_tensor)
            output_details = self.lib.TfLiteTensorNumDims(self.output_tensor)
            input_size = self.lib.TfLiteTensorByteSize(self.input_tensor)
            output_size = self.lib.TfLiteTensorByteSize(self.output_tensor)
            logger.debug(f"Input tensor: dims={input_details}, size={input_size} bytes")
            logger.debug(f"Output tensor: dims={output_details}, size={output_size} bytes")

            # Get quantization parameters
            input_q = self.lib.TfLiteTensorQuantizationParams(self.input_tensor)
            output_q = self.lib.TfLiteTensorQuantizationParams(self.output_tensor)

            self.input_scale, self.input_zero_point = input_q.scale, input_q.zero_point
            self.output_scale, self.output_zero_point = output_q.scale, output_q.zero_point
            logger.debug(f"Quant params - Input: scale={self.input_scale}, zp={self.input_zero_point}; Output: scale={self.output_scale}, zp={self.output_zero_point}")

            load_time = time.time() - start_time
            logger.info(f"Modelo cargado en {load_time:.3f}s")
        except Exception as e:
            logger.error(f"Error cargando modelo: {e}")
            raise

    @classmethod
    def from_config(
        cls,
        config_path: Union[str, Path],
        libtensorflowlite_c_path: Union[str, Path],
    ) -> "MicroWakeWord":
        """Load a microWakeWord model from a JSON config file."""
        start_time = time.time()
        config_path = Path(config_path)
        logger.info(f"Cargando config desde {config_path}")
        try:
            with open(config_path, "r", encoding="utf-8") as config_file:
                config = json.load(config_file)
            logger.debug(f"Config cargada: {json.dumps(config, indent=2)}")  # Log completo para debug

            micro_config = config["micro"]

            instance = cls(
                id=Path(config["model"]).stem,
                wake_word=config["wake_word"],
                tflite_model=config_path.parent / config["model"],
                probability_cutoff=micro_config["probability_cutoff"],
                sliding_window_size=micro_config["sliding_window_size"],
                trained_languages=micro_config.get("trained_languages", []),
                libtensorflowlite_c_path=libtensorflowlite_c_path,
            )
            load_time = time.time() - start_time
            logger.info(f"Instancia MicroWakeWord creada desde config en {load_time:.3f}s")
            return instance
        except Exception as e:
            logger.error(f"Error en from_config: {e}")
            raise

    def process_streaming(self, features: np.ndarray) -> bool:
        start_time = time.time()
        logger.debug(f"Procesando features: shape={features.shape}, min={features.min():.4f}, max={features.max():.4f}, mean={features.mean():.4f}")

        self._features.append(features)

        if len(self._features) < STRIDE:
            logger.debug(f"Features insuficientes: {len(self._features)} < {STRIDE}. No inference")
            return False

        # Allocate and quantize input data
        concat_features = np.concatenate(self._features, axis=1)
        logger.debug(f"Concat features: shape={concat_features.shape}, min={concat_features.min():.4f}, max={concat_features.max():.4f}")

        quant_features = np.round(
            concat_features / self.input_scale + self.input_zero_point
        ).astype(np.uint8)
        logger.debug(f"Quant features: min={quant_features.min()}, max={quant_features.max()}, dtype={quant_features.dtype}")

        # Stride instead of rolling
        self._features.clear()
        logger.debug(f"Features cleared. Buffer size ahora: 0")

        # Set tensor
        quant_ptr = quant_features.ctypes.data_as(ctypes.c_void_p)
        self.lib.TfLiteTensorCopyFromBuffer(
            self.input_tensor, quant_ptr, quant_features.nbytes
        )
        logger.debug("Input tensor copiado")

        # Run inference
        infer_start = time.time()
        self.lib.TfLiteInterpreterInvoke(self.interpreter)
        infer_time = time.time() - infer_start
        logger.debug(f"Inference ejecutada en {infer_time:.3f}s")

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
        probability = result.item()
        logger.debug(f"Output raw: {output_data}, dequant: {probability:.4f}")

        self._probabilities.append(probability)
        logger.debug(f"Probabilidad agregada: {probability:.4f}. Queue size: {len(self._probabilities)}, maxlen={self.sliding_window_size}")

        if len(self._probabilities) < self.sliding_window_size:
            logger.debug(f"Probabilidades insuficientes: {len(self._probabilities)} < {self.sliding_window_size}")
            return False

        mean_prob = statistics.mean(self._probabilities)
        logger.info(f"Mean probability: {mean_prob:.4f} (cutoff: {self.probability_cutoff:.4f})")

        detection = mean_prob > self.probability_cutoff
        if detection:
            logger.warning(f"WAKE WORD DETECTADO! Mean prob: {mean_prob:.4f} > {self.probability_cutoff}")
            # Opcional: Log últimos probs para análisis
            logger.debug(f"Últimas probs: {list(self._probabilities)}")
        else:
            if logger.level == logging.DEBUG:
                logger.debug(f"No detección: {mean_prob:.4f} <= {self.probability_cutoff}")

        process_time = time.time() - start_time
        logger.debug(f"Process_streaming completado en {process_time:.3f}s")

        return detection


# -----------------------------------------------------------------------------


class MicroWakeWordFeatures(TfLiteWakeWord):
    def __init__(
        self,
        libtensorflowlite_c_path: Union[str, Path],
    ) -> None:
        super().__init__(libtensorflowlite_c_path)  # TfLiteWakeWord.__init__(self, libtensorflowlite_c_path)

        self._audio_buffer = bytes()
        self._frontend = MicroFrontend()
        logger.debug(f"MicroWakeWordFeatures init: lib={libtensorflowlite_c_path}")

    def process_streaming(self, audio_bytes: bytes) -> Iterable[np.ndarray]:
        start_time = time.time()
        logger.debug(f"Procesando audio bytes: len={len(audio_bytes)} (total buffer: {len(self._audio_buffer) + len(audio_bytes)} bytes)")

        self._audio_buffer += audio_bytes
        logger.debug(f"Buffer actualizado: len={len(self._audio_buffer)} bytes")

        if len(self._audio_buffer) < BYTES_PER_CHUNK:
            logger.debug(f"Audio insuficiente para chunk: {len(self._audio_buffer)} < {BYTES_PER_CHUNK}")
            return

        audio_buffer_idx = 0
        features_yielded = 0
        while (audio_buffer_idx + BYTES_PER_CHUNK) <= len(self._audio_buffer):
            # Process chunk
            chunk_bytes = self._audio_buffer[
                audio_buffer_idx : audio_buffer_idx + BYTES_PER_CHUNK
            ]
            logger.debug(f"Procesando chunk: len={len(chunk_bytes)} bytes (idx={audio_buffer_idx})")

            frontend_result = self._frontend.ProcessSamples(chunk_bytes)
            samples_read = frontend_result.samples_read * BYTES_PER_SAMPLE
            audio_buffer_idx += samples_read
            logger.debug(f"Frontend procesado: samples_read={frontend_result.samples_read}, features_len={len(frontend_result.features) if frontend_result.features else 0}")

            if not frontend_result.features:
                logger.debug("No features en esta ventana (audio insuficiente)")
                continue

            features = np.array(frontend_result.features).reshape(
                (1, 1, len(frontend_result.features))
            )
            logger.debug(f"Features yield: shape={features.shape}, min={features.min():.4f}, max={features.max():.4f}, mean={features.mean():.4f}")
            yield features
            features_yielded += 1

        logger.debug(f"Features yield total en esta llamada: {features_yielded}. Buffer restante: {len(self._audio_buffer) - audio_buffer_idx} bytes")

        # Remove processed audio
        self._audio_buffer = self._audio_buffer[audio_buffer_idx:]
        process_time = time.time() - start_time
        logger.debug(f"Audio processing completado en {process_time:.3f}s (yielded {features_yielded} features)")
