## Simple Buildroot image for Voice Assistant Satellite for HomeAssistant

This project provides a minimal Buildroot-based image for running Linux Voice Assistant on a Raspberry Pi with a Respeaker v1 (WM8960) hat.

### Supported Devices

| Device | Solution | Hardware | `defconfig` | Comments |
|--------|----------|----------|-------------|----------|
| pi02w/pi3 | **Linux Voice Assistant** | Respeaker v1 (WM8960) | `lva_wm8960hat_pi_3_02w_defconfig` | `fd4c1d972bc87e6d7a0dddc5aa52465243d63265`<br/> _**Latest commit (2025-11-11)**_|

> Note: See mk/config [package](buildroot/external/package/linux-voice-assistant/) folder to change PRs accordingly. Commented is the last commit with `sounddevice` that does not require `pulse`.

### Build

```shell
cd buildroot
docker compose build
docker compose run --rm env
# You will now be inside a bash with the environment setup
make lva_wm8960hat_pi_3_02w_defconfig
make
cp output/images/sdcard.img.xz /repo/
```

### TODO:
- **Wrapper python script for Linux Voice Assistant:** Read `--debug` info to react to states. _(This is a temporary solution to "port" the 2mic led example to lva)_

## Acknowledgments

- **[linux-voice-assistant](https://github.com/OHF-Voice/linux-voice-assistant)** - Voice assistant satellite implementation by OHF-Voice
- **[pymicro-wakeword](https://github.com/OHF-Voice/pymicro-wakeword)** - Efficient TensorFlow-based wake word detection
- **[pyopen-wakeword](https://github.com/rhasspy/pyopen-wakeword)** - Alternative Python library for openWakeWord
