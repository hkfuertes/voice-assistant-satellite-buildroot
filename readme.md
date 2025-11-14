## Simple Buildroot image for Voice Assistant Satellite for HomeAssistant

This project provides minimal Buildroot-based images for running voice assistant satellites on embedded devices. It supports both Wyoming and Linux Voice Assistant protocols, optimized for low-resource ARM devices without requiring PulseAudio.

### Supported Devices

| Device | Solution | Comments |
|--------|----------|----------|
| pi02w/pi3 | **Wyoming** | With Wyoming OpenWakeWord and leds for 2mic Respeaker hat (WM8960). |
| pi02w/pi3 | **Linux Voice Assistant** | `fd4c1d972bc87e6d7a0dddc5aa52465243d63265`<br/> _**Latest commit (2025-11-11)**_|
| proxmox/lxc | **Linux Voice Assistant** | _...same as PI image..._|

> Notes:
> - See mk/config [package](buildroot/external/package/linux-voice-assistant/) folder to change PRs accordingly: Commented is the last commit with `sounddevice` that does not require `pulse`.
> - See [proxmox/post-build](buildroot/external/board/proxmox/post-build.sh) to see an example of `lxc.conf` mounts.

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
---

### TODO:
- ~~Proxmox Amd64 LxC Container~~
- ~~Switch to precompiled library for TensorFlow~~
- ~~Housekeeping, see `triggerhappy-config` package for `source=` example~~
- Config guides insde `guides` folder.

---
## Acknowledgments

- **[linux-voice-assistant](https://github.com/OHF-Voice/linux-voice-assistant)** - Voice assistant satellite implementation by OHF-Voice
- **[pymicro-wakeword](https://github.com/OHF-Voice/pymicro-wakeword)** - Efficient TensorFlow-based wake word detection
- **[pyopen-wakeword](https://github.com/rhasspy/pyopen-wakeword)** - Alternative Python library for openWakeWord
- **[Wyoming Protocol Suite](https://github.com/rhasspy/wyoming)** - Voice assistant communication protocol by rhasspy
