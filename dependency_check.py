#!/usr/bin/env python3
"""
Debug script to check linux-voice-assistant dependencies and versions
"""
import sys
import subprocess
import ctypes
from pathlib import Path

print("=" * 80)
print("LINUX VOICE ASSISTANT - DEPENDENCY DEBUG")
print("=" * 80)

# 1. Python version
print("\n[1] PYTHON VERSION")
print(f"  Version: {sys.version}")
print(f"  Executable: {sys.executable}")

# 2. Python packages
print("\n[2] PYTHON PACKAGES")
packages_check = [
    "numpy",
    "sounddevice",
    "mpv",
    "cffi",
    "zeroconf",
    "pymicro_features",
    "tensorflow",
]

for pkg in packages_check:
    try:
        mod = __import__(pkg)
        version = getattr(mod, "__version__", "unknown")
        location = getattr(mod, "__file__", "unknown")
        print(f"  ✓ {pkg:25} v{version:10} @ {location}")
    except ImportError as e:
        print(f"  ✗ {pkg:25} NOT FOUND - {e}")

# 3. System libraries
print("\n[3] SYSTEM LIBRARIES")
libraries_check = [
    ("libtensorflowlite_c.so", "TensorFlow Lite C API"),
    ("libportaudio.so", "PortAudio"),
    ("libmpv.so", "MPV"),
]

for lib_name, description in libraries_check:
    try:
        lib = ctypes.CDLL(lib_name)
        print(f"  ✓ {lib_name:30} {description}")
    except OSError as e:
        print(f"  ✗ {lib_name:30} NOT FOUND - {e}")

# 4. TensorFlow Lite specifics
print("\n[4] TENSORFLOWLITE SPECIFICS")
try:
    from linux_voice_assistant.wakeword import TfLiteWakeWord
    lib_dir = Path("/usr/lib/python3.13/site-packages/lib/linux_arm64")
    tflite_so = lib_dir / "libtensorflowlite_c.so"
    
    if tflite_so.exists():
        size = tflite_so.stat().st_size
        print(f"  ✓ libtensorflowlite_c.so found")
        print(f"    Size: {size:,} bytes ({size/1024/1024:.2f} MB)")
        print(f"    Path: {tflite_so}")
        
        # Try to load and check for functions
        lib = ctypes.CDLL(str(tflite_so))
        functions = [
            "TfLiteModelCreateFromFile",
            "TfLiteInterpreterCreate",
            "TfLiteInterpreterAllocateTensors",
            "TfLiteInterpreterInvoke",
            "TfLiteTensorQuantizationParams",
            "TfLiteTensorDimensions",
            "TfLiteTensorNumDims",
        ]
        
        print(f"  Checking TfLite functions:")
        for func_name in functions:
            try:
                func = getattr(lib, func_name)
                print(f"    ✓ {func_name}")
            except AttributeError:
                print(f"    ✗ {func_name} NOT FOUND")
    else:
        print(f"  ✗ libtensorflowlite_c.so NOT FOUND at {tflite_so}")
        
except Exception as e:
    print(f"  ✗ Error checking TensorFlow Lite: {e}")

# 5. MicroFeatures specifics
print("\n[5] MICROFEATURES SPECIFICS")
try:
    from pymicro_features import MicroFrontend
    import pymicro_features
    
    print(f"  ✓ pymicro_features imported successfully")
    print(f"    Path: {pymicro_features.__file__}")
    
    # Try to create a frontend
    frontend = MicroFrontend()
    print(f"  ✓ MicroFrontend() instantiated successfully")
    
    # Test with dummy audio
    dummy_audio = b'\x00' * 320  # 160 samples, 16-bit
    result = frontend.ProcessSamples(dummy_audio)
    print(f"  ✓ ProcessSamples() executed")
    print(f"    Samples read: {result.samples_read}")
    print(f"    Features available: {bool(result.features)}")
    if result.features:
        print(f"    Features length: {len(result.features)}")
    
except Exception as e:
    print(f"  ✗ Error with pymicro_features: {e}")
    import traceback
    traceback.print_exc()

# 6. Wake word models
print("\n[6] WAKE WORD MODELS")
wakewords_dir = Path("/usr/lib/python3.13/site-packages/wakewords")

if wakewords_dir.exists():
    print(f"  ✓ Wakewords directory exists: {wakewords_dir}")
    
    tflite_models = list(wakewords_dir.glob("*.tflite"))
    json_configs = list(wakewords_dir.glob("*.json"))
    
    print(f"  Models found: {len(tflite_models)}")
    for model in sorted(tflite_models)[:5]:
        size = model.stat().st_size
        print(f"    - {model.name:30} ({size:,} bytes)")
    
    print(f"  Configs found: {len(json_configs)}")
    for config in sorted(json_configs)[:5]:
        print(f"    - {config.name}")
    
    # Check okay_nabu specifically
    okay_nabu_model = wakewords_dir / "okay_nabu.tflite"
    okay_nabu_config = wakewords_dir / "okay_nabu.json"
    
    if okay_nabu_model.exists():
        print(f"  ✓ okay_nabu.tflite exists ({okay_nabu_model.stat().st_size:,} bytes)")
    else:
        print(f"  ✗ okay_nabu.tflite NOT FOUND")
    
    if okay_nabu_config.exists():
        print(f"  ✓ okay_nabu.json exists")
        import json
        with open(okay_nabu_config) as f:
            config = json.load(f)
            print(f"    Type: {config.get('type')}")
            print(f"    Wake word: {config.get('wake_word')}")
            if 'micro' in config:
                print(f"    Cutoff: {config['micro'].get('probability_cutoff')}")
    else:
        print(f"  ✗ okay_nabu.json NOT FOUND")
else:
    print(f"  ✗ Wakewords directory NOT FOUND: {wakewords_dir}")

# 7. Audio input device
print("\n[7] AUDIO INPUT DEVICE")
try:
    import sounddevice as sd
    devices = sd.query_devices()
    
    # Find default input
    default_in = sd.default.device[0]
    if default_in >= 0:
        device = devices[default_in]
        print(f"  ✓ Default input device: {device['name']}")
        print(f"    Max channels: {device['max_input_channels']}")
        print(f"    Supported sample rates: {device.get('supported_samplerates', 'unknown')}")
    
    # Check for wm8960
    print(f"\n  Available input devices:")
    for i, device in enumerate(devices):
        if device['max_input_channels'] > 0:
            print(f"    [{i}] {device['name']:40} (in_ch={device['max_input_channels']})")
            
except Exception as e:
    print(f"  ✗ Error checking audio: {e}")

# 8. Summary
print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)

issues = []

# Check critical packages
try:
    import pymicro_features
    from pymicro_features import MicroFrontend
except:
    issues.append("pymicro_features not working properly")

try:
    import sounddevice
except:
    issues.append("sounddevice not installed")

try:
    lib = ctypes.CDLL("/usr/lib/python3.13/site-packages/lib/linux_arm64/libtensorflowlite_c.so")
except:
    issues.append("libtensorflowlite_c.so not loadable")

if not Path("/usr/lib/python3.13/site-packages/wakewords/okay_nabu.tflite").exists():
    issues.append("okay_nabu.tflite model not found")

if issues:
    print(f"\n⚠️  POTENTIAL ISSUES FOUND ({len(issues)}):")
    for issue in issues:
        print(f"  - {issue}")
else:
    print("\n✓ All critical dependencies appear to be present")

print("\n" + "=" * 80)
