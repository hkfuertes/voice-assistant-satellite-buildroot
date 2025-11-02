# Snippet 8: test_interpreter_health.py
# Verifica si el intérprete está vivo

import ctypes
import numpy as np

lib_path = "/usr/lib/libtensorflowlite_c.so"
model_path = "/usr/lib/python3.13/site-packages/wakewords/okay_nabu.tflite"

lib = ctypes.CDLL(lib_path)

def get_func(name, argtypes, restype):
    func = getattr(lib, name)
    func.argtypes = argtypes
    func.restype = restype
    return func

# Funciones básicas
TfLiteModelCreateFromFile = get_func("TfLiteModelCreateFromFile", [ctypes.c_char_p], ctypes.c_void_p)
TfLiteInterpreterCreate = get_func("TfLiteInterpreterCreate", [ctypes.c_void_p, ctypes.c_void_p], ctypes.c_void_p)
TfLiteInterpreterAllocateTensors = get_func("TfLiteInterpreterAllocateTensors", [ctypes.c_void_p], ctypes.c_int)
TfLiteInterpreterGetInputTensor = get_func("TfLiteInterpreterGetInputTensor", [ctypes.c_void_p, ctypes.c_int], ctypes.c_void_p)
TfLiteInterpreterGetOutputTensor = get_func("TfLiteInterpreterGetOutputTensor", [ctypes.c_void_p, ctypes.c_int], ctypes.c_void_p)
TfLiteTensorShape = get_func("TfLiteTensorDimensions", [ctypes.c_void_p], ctypes.POINTER(ctypes.c_int))
TfLiteTensorNumDims = get_func("TfLiteTensorNumDims", [ctypes.c_void_p], ctypes.c_int)
TfLiteTensorType = get_func("TfLiteTensorType", [ctypes.c_void_p], ctypes.c_int)
TfLiteTensorQuantizationParams = get_func("TfLiteTensorQuantizationParams", [ctypes.c_void_p], None)
TfLiteTensorByteSize = get_func("TfLiteTensorByteSize", [ctypes.c_void_p], ctypes.c_int)
TfLiteTensorCopyFromBuffer = get_func("TfLiteTensorCopyFromBuffer", [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int], ctypes.c_void_p)
TfLiteInterpreterInvoke = get_func("TfLiteInterpreterInvoke", [ctypes.c_void_p], ctypes.c_int)
TfLiteTensorCopyToBuffer = get_func("TfLiteTensorCopyToBuffer", [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int], ctypes.c_int)

print("=== MODEL HEALTH CHECK ===\n")

print("1. Loading model...")
model = TfLiteModelCreateFromFile(model_path.encode('utf-8'))
print(f"   Model pointer: {model}")
if not model:
    print("   ERROR: Model is NULL!")
    exit(1)

print("\n2. Creating interpreter...")
interpreter = TfLiteInterpreterCreate(model, None)
print(f"   Interpreter pointer: {interpreter}")
if not interpreter:
    print("   ERROR: Interpreter is NULL!")
    exit(1)

print("\n3. Allocating tensors...")
alloc_result = TfLiteInterpreterAllocateTensors(interpreter)
print(f"   Allocation result: {alloc_result}")

print("\n4. Getting input tensor...")
input_tensor = TfLiteInterpreterGetInputTensor(interpreter, 0)
print(f"   Input tensor pointer: {input_tensor}")

print("\n5. Getting output tensor...")
output_tensor = TfLiteInterpreterGetOutputTensor(interpreter, 0)
print(f"   Output tensor pointer: {output_tensor}")

print("\n6. Input tensor info:")
input_bytes = TfLiteTensorByteSize(input_tensor)
print(f"   Input size: {input_bytes} bytes")

print("\n7. Output tensor info:")
output_bytes = TfLiteTensorByteSize(output_tensor)
print(f"   Output size: {output_bytes} bytes")

print("\n8. Testing inference with pattern...")
# Crea patrón: primeros 40 = 100, siguientes 40 = 150, últimos 40 = 200
test_input = np.concatenate([
    np.full(40, 100, dtype=np.uint8),
    np.full(40, 150, dtype=np.uint8),
    np.full(40, 200, dtype=np.uint8)
])
print(f"   Input pattern: first 40=100, mid 40=150, last 40=200")
print(f"   Total input bytes: {len(test_input)}")

input_ptr = test_input.ctypes.data_as(ctypes.c_void_p)
copy_result = TfLiteTensorCopyFromBuffer(input_tensor, input_ptr, len(test_input))
print(f"   Copy result: {copy_result}")

print("\n9. Running inference...")
invoke_result = TfLiteInterpreterInvoke(interpreter)
print(f"   Invoke result: {invoke_result}")

print("\n10. Reading output...")
output_data = np.empty(output_bytes, dtype=np.uint8)
output_ptr = output_data.ctypes.data_as(ctypes.c_void_p)
read_result = TfLiteTensorCopyToBuffer(output_tensor, output_ptr, output_bytes)
print(f"    Read result: {read_result}")
print(f"    Output raw bytes: {output_data}")
print(f"    Output as uint8: {list(output_data)}")

# Intenta leerlo como int8 también
output_data_int8 = output_data.astype(np.int8)
print(f"    Output as int8: {list(output_data_int8)}")

print("\n=== SUMMARY ===")
if invoke_result == 0 and all(output_data == 0):
    print("⚠️  Model runs but always outputs 0")
    print("    Possibilities:")
    print("    - Model is trained differently")
    print("    - Binary incompatibility (musl/glibc)")
    print("    - Output tensor is not being written")
elif invoke_result != 0:
    print("❌ Inference failed with error code:", invoke_result)
else:
    print("✅ Model is working")
