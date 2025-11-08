## Simple Buildroot image for Voice Assistant Satellite for HomeAssistant
This project aims to generate a minimal image with two Voice Assistant solutions.

### Devices
| Device | Solution | Comments |
|--------|----------|----------|
| pi02w/pi3 | **Wyoming** | With Wyoming OpenWakeWord and leds for 2mic Respeaker hat (WM8960). |
| pi02w/pi3 | **Linux Voice Assistant** | `72c8f021c8152f427d4e622a920860bacf8c7fc3` (last commit con sounddevice instead of soundcard, no pulse needed)<br/>_Only openWakeWord at the moment._ |
| pi02w/pi3 (armv7) | - | - |
| UZ801 Family | - | - |
| Amazon Biscuit (armv7) | - | - |

### Setup
Zeroconf is enabled by default, so once the device is in the wifi it should be autodiscovered by Home Assistant.

To connect to wifi, place a `wpa_supplicant.conf` file in the `/boot` partition.

### Build
```shell
cd buildroot
docker compose build
docker compose run --rm env
# You will now be inside a bash with the environment setup
# make lva_raspberrypi_3_zero2w_64_defconfig
make wyoming_raspberrypi_3_zero2w_64_defconfig
make
cp output/images/sdcard.img.xz /repo/
```
---
### TODO:
The end goal (if dreaming is free) is to have `linux-voice-assistant` running with `microwakeword` on the Amazon Echo Dot 2nd (`amazon-biscuit`) with this buildroot as rootfs and pmOS kernel.
- Make `microWakeWord` work on current pi arm64 image.
- Make armv7 image for curent pi
- Test building this for the UZ801 dongle with an usb conference speaker/mic
- Test pmOS on my Echo Dot.
- Test build for Echo Dot, following the same recipe used for UZ801, as the only current kernel I found was pmOS's