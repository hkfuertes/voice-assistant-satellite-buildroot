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
/opt/wyoming/satellite/.venv/bin/pip3 install rpi-lgpio spidev

# Install OpenWakeWord
cd /opt/wyoming
git clone https://github.com/rhasspy/wyoming-openwakeword.git wakeword
cd wakeword
script/setup

# Configure ReSpeaker 2-Mic HAT
sudo bash -c 'cat >> /boot/firmware/config.txt' << 'EOF'
dtparam=i2c_arm=on
dtparam=spi=on
dtoverlay=wm8960-soundcard
EOF

# Disable HDMI output
sudo sed -i '/dtoverlay=vc4-fkms-v3d/s/^/#/' /boot/firmware/config.txt

# Reboot to load drivers
sudo reboot
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
After=network-online.target wyoming-openwakeword.service 2mic_leds.service
Requires=wyoming-openwakeword.service 2mic_leds.service

[Service]
Type=simple
ExecStart=/opt/wyoming/satellite/.venv/bin/python3 script/run \
  --name 'my satellite' \
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
ExecStart=/opt/wyoming/wakeword/.venv/bin/python3 script/run --uri 'tcp://127.0.0.1:10400'
WorkingDirectory=/opt/wyoming/wakeword
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
ExecStart=/opt/wyoming/satellite/.venv/bin/python3 2mic_service.py --uri 'tcp://127.0.0.1:10500'
WorkingDirectory=/opt/wyoming/satellite/examples
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
```
