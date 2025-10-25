## Respeaker Drivers
Follow this [guide](respeaker/readme.md).

## Wyoming Satellite

```shell
sudo apt update
sudo apt install -y git alsa-utils caps gcc git python3-dev python3-venv libopenblas-dev swig libgpiod-dev liblgpio-dev

# Create system directory
sudo mkdir -p /opt/wyoming
sudo chown $USER:$USER /opt/wyoming

# Clone Wyoming Satellite
cd /opt/wyoming
git clone https://github.com/rhasspy/wyoming-satellite.git satellite
cd satellite
git checkout 13bb0249310391bb7b7f6e109ddcc0d7d76223c1
script/setup

# Install GPIO/SPI dependencies for LEDs
/opt/wyoming/satellite/.venv/bin/pip3 install rpi-lgpio spidev gpiozero
sudo echo "dtparam=spi=on" >> /boot/firmware/config.txt

# Install OpenWakeWord
cd /opt/wyoming
git clone https://github.com/rhasspy/wyoming-openwakeword.git openwakeword
cd openwakeword
script/setup

# Force module name no matter the folder installed
sed -i 's/_MODULE = _PROGRAM_DIR.name.replace("-", "_")/_MODULE = "wyoming_openwakeword"/' script/run
```
## Services
```shell
sudo nano /etc/systemd/system/wyoming-openwakeword.service
sudo nano /etc/systemd/system/wyoming-2mic-leds.service
sudo nano /etc/systemd/system/wyoming-satellite.service
```

### Satellite Service
```ini
[Unit]
Description=Wyoming Satellite
Wants=network-online.target
After=network-online.target wyoming-openwakeword.service wyoming-2mic-leds.service
Requires=wyoming-openwakeword.service wyoming-2mic-leds.service

[Service]
Type=simple
ExecStart=/opt/wyoming/satellite/.venv/bin/python3 /opt/wyoming/satellite/script/run \
  --name 'AssistPi' \
  --uri 'tcp://0.0.0.0:10700' \
  --mic-command 'arecord -D plughw:CARD=seeed2micvoicec,DEV=0 -r 16000 -c 1 -f S16_LE -t raw' \
  --snd-command 'aplay -D plughw:CARD=seeed2micvoicec,DEV=0 -r 22050 -c 1 -f S16_LE -t raw' \
  --wake-uri 'tcp://127.0.0.1:10400' \
  --wake-word-name 'ok_nabu' \
  --event-uri 'tcp://127.0.0.1:10500'
WorkingDirectory=/opt/wyoming/satellite
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
```

### OpenWakeWord Service
```ini
[Unit]
Description=Wyoming OpenWakeWord

[Service]
Type=simple
ExecStart=/opt/wyoming/openwakeword/.venv/bin/python3 /opt/wyoming/openwakeword/script/run --uri 'tcp://127.0.0.1:10400'
WorkingDirectory=/opt/wyoming/openwakeword
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
```

### LED Service
```ini
[Unit]
Description=2Mic LEDs

[Service]
Type=simple
ExecStart=/opt/wyoming/satellite/.venv/bin/python3 /opt/wyoming/satellite/examples/2mic_service.py \
            --uri 'tcp://127.0.0.1:10500' \
            --led-brightness 10
WorkingDirectory=/opt/wyoming/satellite/examples
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
```
