# Snippet 9: test_interpreter_health_simple.py

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

# Solo funciones que existen
TfLiteModelCreateFromFile = get_func("TfLiteModelCreateFromFile", [ctypes.c_char_p], ctypes.c_void_p)
TfLiteInterpreterCreate = get_func("TfLiteInterpreterCreate", [ctypes.c_void_p, ctypes.c_void_p], ctypes.c_void_p)
TfLiteInterpreterAllocateTensors = get_func("TfLiteInterpreterAllocateTensors", [ctypes.c_void_p], ctypes.c_int)
TfLiteInterpreterGetInputTensor = get_func("TfLiteInterpreterGetInputTensor", [ctypes.c_void_p, ctypes.c_int], ctypes.c_void_p)
TfLiteInterpreterGetOutputTensor = get_func("TfLiteInterpreterGetOutputTensor", [ctypes.c_void_p, ctypes.c_int], ctypes.c_void_p)
TfLiteTensorByteSize = get_func("TfLiteTensorByteSize", [ctypes.c_void_p], ctypes.c_int)
TfLiteTensorCopyFromBuffer = get_func("TfLiteTensorCopyFromBuffer", [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int], ctypes.c_void_p)
TfLiteInterpreterInvoke = get_func("TfLiteInterpreterInvoke", [ctypes.c_void_p], ctypes.c_int)
TfLiteTensorCopyToBuffer = get_func("TfLiteTensorCopyToBuffer", [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int], ctypes.c_int)

print("=== MODEL HEALTH CHECK ===\n")

print("1. Loading model...")
model = TfLiteModelCreateFromFile(model_path.encode('utf-8'))
print(f"   Model pointer: {model}")

print("\n2. Creating interpreter...")
interpreter = TfLiteInterpreterCreate(model, None)
print(f"   Interpreter pointer: {interpreter}")

print("\n3. Allocating tensors...")
alloc_result = TfLiteInterpreterAllocateTensors(interpreter)
print(f"   Allocation result: {alloc_result}")

print("\n4. Getting input tensor...")
input_tensor = TfLiteInterpreterGetInputTensor(interpreter, 0)
print(f"   Input tensor pointer: {input_tensor}")

print("\n5. Getting output tensor...")
output_tensor = TfLiteInterpreterGetOutputTensor(interpreter, 0)
print(f"   Output tensor pointer: {output_tensor}")

print("\n6. Input tensor size:")
input_bytes = TfLiteTensorByteSize(input_tensor)
print(f"   {input_bytes} bytes")

print("\n7. Output tensor size:")
output_bytes = TfLiteTensorByteSize(output_tensor)
print(f"   {output_bytes} bytes")

print("\n8. Testing inference with pattern (100,150,200)...")
test_input = np.concatenate([
    np.full(40, 100, dtype=np.uint8),
    np.full(40, 150, dtype=np.uint8),
    np.full(40, 200, dtype=np.uint8)
])

input_ptr = test_input.ctypes.data_as(ctypes.c_void_p)
TfLiteTensorCopyFromBuffer(input_tensor, input_ptr, len(test_input))

print("9. Running inference...")
invoke_result = TfLiteInterpreterInvoke(interpreter)
print(f"   Result code: {invoke_result}")

print("\n10. Reading output...")
output_data = np.empty(output_bytes, dtype=np.uint8)
output_ptr = output_data.ctypes.data_as(ctypes.c_void_p)
TfLiteTensorCopyToBuffer(output_tensor, output_ptr, output_bytes)
print(f"    Output raw: {output_data}")
print(f"    Output hex: {output_data.hex()}")

print("\n=== CONCLUSION ===")
if invoke_result == 0:
    if all(output_data == 0):
        print("❌ Model runs but ALWAYS outputs zero")
        print("   This means: librería NO es compatible con Buildroot")
        print("   Solution: Recompila TensorFlow Lite en Buildroot")
    else:
        print("✅ Model is working! Output changed based on input")
else:
    print(f"❌ Inference failed with code: {invoke_result}")
