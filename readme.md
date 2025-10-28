# voice-assistant-satellite-buildroot

A custom Buildroot configuration for Raspberry Pi Zero 2W and Raspberry Pi 3 that provides a complete Wyoming protocol voice assistant satellite with wake word detection.

## Features

- **Target Hardware**: Raspberry Pi Zero 2W and Raspberry Pi 3 (64-bit)
- **Wyoming Suite Integration**: Full Wyoming protocol satellite implementation for Home Assistant voice assistant
- **Pre-configured Audio**: Optimized for ReSpeaker 2-Mic HAT v1
- **Wake Word Detection**: Includes both microwakeword and openwakeword engines
- **WiFi Auto-configuration**: Simple WiFi setup via boot partition
- **Auto Root Expansion**: Automatically expands root filesystem on first boot
- **USB Serial Gadget**: SSH over USB using ACM serial console

## Current Status

⚠️ **Work in Progress**: Microwakeword engine runs without errors but voice recognition is not working reliably. This is actively being debugged.

## Quick Start

### Prerequisites

- Docker and Docker Compose
- 8GB+ SD card for target device
- ReSpeaker 2-Mic HAT v1 (recommended)

### Building the Image

1. Clone this repository:
```bash
git clone <your-repo-url>
cd voice-assistant-satellite-buildroot/buildroot
```

2. Build directly using Docker Compose:
```bash
docker compose run --rm build
```

The compiled image will be available as `wyoming-satellite-rpi0w2-rpi3.img.xz` in the buildroot directory.

### Interactive Development

For manual configuration and development:

```bash
docker compose run --rm env
```

This opens an interactive shell inside the Buildroot environment where you can run:
```bash
make raspberrypi_3_zero2w_64_defconfig
make menuconfig  # Optional: customize configuration
make -j$(nproc)
```

## Alternative: Manual Installation on Raspberry Pi OS

If you prefer to install Wyoming suite manually on an existing Raspberry Pi OS installation (without microwakeword), check the `guides/` directory for step-by-step instructions.

## WiFi Configuration

### Method 1: Pre-configured Image (Build Time)

If you're compiling the image yourself, place your `wpa_supplicant.conf` at:
```
buildroot/external/package/wifi-autoconfig/files/wpa_supplicant.conf
```

Example configuration:
```conf
ctrl_interface=/var/run/wpa_supplicant
update_config=1
country=ES

network={
    ssid="YourNetworkName"
    psk="YourPassword"
    key_mgmt=WPA-PSK
}
```

### Method 2: Runtime Configuration (Recommended)

1. Flash the image to your SD card
2. Mount the boot partition (e.g., `/dev/mmcblk0p1`)
3. Copy your `wpa_supplicant.conf` to the boot partition root
4. Unmount and boot the device

The init script `S39wifi-autoconfig` automatically:
- Detects `wpa_supplicant.conf` on boot partition
- Copies it to `/etc/wpa_supplicant.conf`
- Configures and starts WiFi
- Disables WiFi power management for better reliability

## Wyoming Satellite Configuration

Wyoming Satellite settings can only be configured at **build time**. Edit the configuration in:
```
buildroot/external/package/wyoming-satellite/Config.in
```

Available options:
- `BR2_PACKAGE_WYOMING_SATELLITE_NAME`: Satellite name (default: "AssistPi")
- `BR2_PACKAGE_WYOMING_SATELLITE_WAKE_URI`: Wake word service URI (default: "tcp://127.0.0.1:10400")
- `BR2_PACKAGE_WYOMING_SATELLITE_WAKE_WORD`: Wake word to use (default: "ok_nabu")
- `BR2_PACKAGE_WYOMING_SATELLITE_LEDS`: Enable ReSpeaker LED support

After modifying, rebuild with:
```bash
docker compose run --rm env
# Inside the container:
make menuconfig  # Navigate to External options -> wyoming-satellite
make
```

## ReSpeaker 2-Mic HAT v1 Support

This build is optimized for the ReSpeaker 2-Mic HAT v1 with automatic configuration:

- **WM8960 codec driver** compiled as kernel module
- **ALSA configuration** pre-installed (`/etc/asound.conf`)
- **Device tree overlays** automatically applied to `config.txt`
- **I2C and I2S** interfaces enabled
- **LED support** optional via Wyoming Satellite configuration

The `respeaker-config` package handles all setup automatically on boot via the `S50respeaker` init script.

## USB Serial Access

The image provides USB ACM serial gadget support for SSH access over USB. Simply connect a micro USB cable from your computer to the Pi's data port (not the power port).

### Linux

1. Enable the CDC ACM driver if not already loaded:
```bash
sudo modprobe cdc_acm
```

2. Install minicom if not already installed:
```bash
sudo apt-get install minicom
```

3. Find the USB serial device by checking dmesg or listing devices:
```bash
dmesg | grep tty
ls /dev/ttyACM*
```

4. Connect using minicom:
```bash
minicom -b 115200 -D /dev/ttyACM<N>
```

Replace `<N>` with the appropriate number for your device.

5. To exit minicom: Press `Ctrl+A`, then `X`, then confirm with `Enter`.

## Useful Commands

### Testing microphone functionality

Verify the microphone is responding:
```bash
arecord -V mono -f cd /dev/null
```

This records audio and discards it, showing real-time audio level meters to confirm the microphone is working properly.

### Check ALSA devices
```bash
arecord -l
aplay -l
```

### View audio configuration
```bash
cat /etc/asound.conf
```

## Project Structure

```
voice-assistant-satellite-buildroot/
├── buildroot/
│   ├── dependencies.sh          # Shared dependency installation script
│   ├── dockerfile               # Docker build environment
│   ├── docker-compose.yml       # Build orchestration
│   ├── prebuild.sh              # Compiles Python wheels that Buildroot cannot build
│   ├── external/                # BR2_EXTERNAL tree
│   │   ├── board/               # Board-specific files and scripts
│   │   ├── configs/             # Custom defconfig
│   │   └── package/             # Custom packages
│   │       ├── expand-rootfs/
│   │       ├── respeaker-config/
│   │       ├── wifi-autoconfig/
│   │       ├── wyoming-microwakeword/
│   │       ├── wyoming-openwakeword/
│   │       └── wyoming-satellite/
└── guides/                      # Manual installation guides for Raspberry Pi OS
```

**Note on prebuild.sh**: This script pre-compiles Python wheel files (.whl) that Buildroot's cross-compilation toolchain cannot build natively. The pre-compiled wheels are already included in the project tree, so you don't need to run this script unless modifying Python package versions.

## Docker Compose Services

The project provides two Docker Compose services:

### `env` - Interactive Development Environment
```bash
docker compose run --rm env
```
Opens an interactive bash shell with:
- All build dependencies pre-installed
- Buildroot 2025.08.x checked out
- BR2_EXTERNAL configured to `/repo/external`
- Persistent download cache in Docker volume

Use this for manual builds, menuconfig, or debugging.

### `build` - Automated Build
```bash
docker compose run --rm build
```
Automatically runs the complete build process:
1. Loads the defconfig
2. Compiles the entire system
3. Outputs `wyoming-satellite-rpi0w2-rpi3.img.xz` to the buildroot directory

The `--rm` flag ensures containers are cleaned up after execution.

## Custom Packages

### Core Packages
- **wyoming-satellite**: Main voice assistant satellite service
- **wyoming-microwakeword**: Fast wake word detection (WIP)
- **wyoming-openwakeword**: Alternative wake word engine

### System Packages
- **wifi-autoconfig**: Automatic WiFi configuration from boot partition
- **respeaker-config**: ReSpeaker HAT driver configuration
- **expand-rootfs**: Auto-expand root filesystem on first boot
- **usb-gadget**: USB ACM serial gadget for console access
- **extra-configs**: System-level configurations and optimizations

## GitHub Actions CI/CD

The project includes automated builds via GitHub Actions. The workflow:

- Automatically builds on push/PR
- Caches Buildroot downloads for faster builds
- Uploads compiled images as artifacts
- Supports manual workflow dispatch

Artifacts are available for download from the Actions tab after successful builds.

## Flashing the Image

### Linux
```bash
xzcat wyoming-satellite-rpi0w2-rpi3.img.xz | sudo dd of=/dev/sdX bs=4M status=progress
sync
```

Replace `/dev/sdX` with your SD card device.

## First Boot

1. Insert SD card with flashed image
2. (Optional) Copy `wpa_supplicant.conf` to boot partition for WiFi
3. Power on the device
4. Wait for root filesystem expansion (happens automatically)
5. Connect via SSH (after WiFi connects or via USB serial console)

Default credentials:
- Username: `root`
- Password: `toor`

## Acknowledgments

- [Buildroot](https://buildroot.org/) - Embedded Linux build system
- [Wyoming Protocol](https://github.com/rhasspy/wyoming) - Voice assistant protocol
- [Home Assistant](https://www.home-assistant.io/) - Smart home platform
- [ReSpeaker](https://wiki.seeedstudio.com/ReSpeaker_2_Mics_Pi_HAT/) - Audio HAT hardware
