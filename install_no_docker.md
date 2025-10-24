## Wyoming Satellite
```shell
sudo apt update
sudo apt install -y alsa-utils caps gcc git python3-dev libopenblas-dev

# Install Satellite and Leds
git clone -b 13bb0249310391bb7b7f6e109ddcc0d7d76223c1 https://github.com/rhasspy/wyoming-satellite.git
cd wyoming-satellite

# Create venv and install dependencies
python3 -m venv /opt/wyoming/venv
/opt/wyoming/venv/bin/pip3 install --upgrade pip wheel setuptools
/opt/wyoming/venv/bin/pip3 install -r requirements.txt
/opt/wyoming/venv/bin/pip3 install rpi-lgpio spidev gpiozero

# Setup Satellite
script/setup

# Run -> scripts/run
# Leds -> examples/2mic_service.py

# Install OpenWakeworkd
cd ..
git clone https://github.com/rhasspy/wyoming-openwakeword.git
cd wyoming-openwakeword
script/setup
```

Satellite Service
```service
[Unit]
Description=Wyoming Satellite
Wants=network-online.target
After=network-online.target
Requires=wyoming-openwakeword.service
Requires=2mic_leds.service

[Service]
Type=simple
ExecStart=/home/pi/wyoming-satellite/script/run \
  --name 'my satellite' \
  --uri 'tcp://0.0.0.0:10700' \
  --mic-command 'arecord -D plughw:CARD=seeed2micvoicec,DEV=0 -r 16000 -c 1 -f S16_LE -t raw' \
  --snd-command 'aplay -D plughw:CARD=seeed2micvoicec,DEV=0 -r 22050 -c 1 -f S16_LE -t raw' \
  --wake-uri 'tcp://127.0.0.1:10400' \
  --wake-word-name 'ok_nabu' \
  --event-uri 'tcp://127.0.0.1:10500'
WorkingDirectory=/home/pi/wyoming-satellite
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
```

OpenWakeword Service
```service
[Unit]
Description=Wyoming openWakeWord

[Service]
Type=simple
ExecStart=/home/pi/wyoming-openwakeword/script/run --uri 'tcp://127.0.0.1:10400'
WorkingDirectory=/home/pi/wyoming-openwakeword
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
```

Led Service
```
[Unit]
Description=2Mic LEDs

[Service]
Type=simple
ExecStart=/home/pi/wyoming-satellite/examples/.venv/bin/python3 2mic_service.py --uri 'tcp://127.0.0.1:10500'
WorkingDirectory=/home/pi/wyoming-satellite/examples
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
```


```
echo "[STEP 7/12] Configuring ReSpeaker 2-Mic HAT..."
mkdir -p "${ROOTFS}/boot"
cat >> "${ROOTFS}/boot/usercfg.txt" <<EOF
# ReSpeaker 2-Mic HAT
dtparam=i2c_arm=on
dtparam=spi=on
dtoverlay=wm8960-soundcard
EOF

# Load modules on boot
cat > "${ROOTFS}/etc/modules" <<EOF
snd-soc-wm8960
i2c-dev
spidev
EOF
```
