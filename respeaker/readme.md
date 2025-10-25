```shell
# Configure ReSpeaker 2-Mic HAT
sudo bash -c 'cat >> /boot/firmware/config.txt' << 'EOF'
dtparam=i2c_arm=on
dtparam=spi=on
dtoverlay=wm8960-soundcard
EOF

# Disable HDMI output
sudo sed -i '/dtoverlay=vc4-fkms-v3d/s/^/#/' /boot/firmware/config.txt

# Alsa mixer default configs
# cp asound.conf /etc/asound.conf
sudo bash -c 'cat > /etc/asound.conf' << 'EOF'
pcm.!default {
    type asym
    playback.pcm {
        type plug
        slave.pcm "hw:wm8960soundcard,0"
    }
    capture.pcm {
        type plug
        slave.pcm "hw:wm8960soundcard,0"
    }
}

ctl.!default {
    type hw
    card wm8960soundcard
}
EOF

# cp setup-respeaker-v1.sh /usr/local/bin/setup-respeaker-v1.sh
sudo bash -c 'cat > /usr/local/bin/setup-respeaker-v1.sh' << 'EOF'
#!/bin/bash
# ReSpeaker 2-Mic HAT v1 ALSA configuration

CARD="wm8960soundcard"

# Wait for card to be ready
sleep 2

# Capture controls
amixer -c "$CARD" sset 'Capture' 100% unmute cap 2>/dev/null
amixer -c "$CARD" sset 'ADC PCM' 195 2>/dev/null

# Input boost
amixer -c "$CARD" sset 'Left Input Mixer Boost' on 2>/dev/null
amixer -c "$CARD" sset 'Right Input Mixer Boost' on 2>/dev/null
amixer -c "$CARD" sset 'Left Input PGA Boost' on 2>/dev/null
amixer -c "$CARD" sset 'Right Input PGA Boost' on 2>/dev/null

# Input routing
amixer -c "$CARD" sset 'Left Input' 'MIC2' 2>/dev/null
amixer -c "$CARD" sset 'Right Input' 'MIC2' 2>/dev/null

# Playback
amixer -c "$CARD" sset 'Playback' 100% unmute 2>/dev/null
amixer -c "$CARD" sset 'Speaker' 100% unmute 2>/dev/null

# Save state
alsactl store 2>/dev/null

echo "ReSpeaker 2-Mic HAT v1 configured"
EOF

sudo chmod +x /usr/local/bin/setup-respeaker-v1.sh

# Install Service
# cp respeaker-setup.service /etc/systemd/system/respeaker-setup.service
sudo bash -c 'cat > /etc/systemd/system/respeaker-setup.service' << 'EOF'
[Unit]
Description=ReSpeaker 2-Mic HAT v1 ALSA Setup
After=sound.target alsa-restore.service
Wants=sound.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/setup-respeaker-v1.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable respeaker-setup.service
```
