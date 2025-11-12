## Simple Buildroot image for Voice Assistant Satellite for HomeAssistant

This project provides minimal Buildroot-based images for running voice assistant satellites on embedded devices. It supports both Wyoming and Linux Voice Assistant protocols, optimized for low-resource ARM devices without requiring PulseAudio.

**Key features:**
- Minimal footprint (~100MB images)
- Zero-configuration with mDNS/Zeroconf
- Support for WM8960 2mic Respeaker HAT

---

### Supported Devices

| Device | Solution | Comments |
|--------|----------|----------|
| pi02w/pi3 | **Wyoming** | With Wyoming OpenWakeWord and leds for 2mic Respeaker hat (WM8960). |
| pi02w/pi3 | **Linux Voice Assistant** | <ul> <li>`72c8f021c8152f427d4e622a920860bacf8c7fc3`: Last commit with `sounddevice` (no pulse needed)</li> <li>`2b04484f4c225773130cd137c49ea443e2c6e9c5`: Latest commit (2025-11-09) using `soundcard`</li></ul>|

> See mk/config [package](buildroot/external/package/linux-voice-assistant/) folder to change PRs accordingly
---

### Prerequisites

- Docker and Docker Compose
- 4GB+ microSD card
- Supported hardware (see Devices table)
- Home Assistant instance with ESPHome integration

---

### Hardware Setup

#### Raspberry Pi Zero 2W / Pi 3
- Respeaker 2-Mic Pi HAT (WM8960) recommended
- Power supply: 5V/2.5A minimum
- MicroSD card: 4GB minimum, Class 10 recommended
---

### Build

```shell
cd buildroot
docker compose build
docker compose run --rm env
# You will now be inside a bash with the environment setup
make lva_raspberrypi_3_zero2w_64_defconfig
make
cp output/images/sdcard.img.xz /repo/
```
---

### Configuration

#### WiFi Setup

Zeroconf is enabled by default, so once the device is connected to WiFi it should be autodiscovered by Home Assistant.

To connect to WiFi, create a `wpa_supplicant.conf` file in the `/boot` partition:

```conf
country=ES
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YourSSID"
    psk="YourPassword"
}
```

#### Home Assistant Integration

The device will auto-discover via Zeroconf. Alternatively, manually add:

1. Go to Settings → Devices & Services
2. Add Integration → ESPHome
3. Enter device IP: `192.168.x.x:6053`

---

### ROADMAP _(... or distant future ...)_

The end goal (if dreaming is free) is to have `linux-voice-assistant` running with `microwakeword` on the Amazon Echo Dot 2nd (`amazon-biscuit`) with this buildroot as rootfs and pmOS kernel.

- ~~Make `microWakeWord` work on current pi arm64 image~~
- Proxmox AMD64 LxC container...
- Make armv7 image for current pi
- Test building this for the UZ801 dongle (uses pmOS kernel and its aarch64 capable) with an usb conference speaker/mic
- Test pmOS on my Echo Dot
- Test build for Echo Dot, following the same recipe used for UZ801, as the only current kernel I found was pmOS's
- ...
- _... and when I inevitably fail... replace the TensorFlow Lite version compiled by Buildroot with some precompiled binary..._

---
## Acknowledgments

- **[linux-voice-assistant](https://github.com/OHF-Voice/linux-voice-assistant)** - Voice assistant satellite implementation by OHF-Voice
- **[pymicro-wakeword](https://github.com/OHF-Voice/pymicro-wakeword)** - Efficient TensorFlow-based wake word detection
- **[pyopen-wakeword](https://github.com/rhasspy/pyopen-wakeword)** - Alternative Python library for openWakeWord
- **[Wyoming Protocol Suite](https://github.com/rhasspy/wyoming)** - Voice assistant communication protocol by rhasspy
