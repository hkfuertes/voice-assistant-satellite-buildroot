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
cp asound.conf /etc/asound.conf
cp setup-respeaker-v1.sh /usr/local/bin/setup-respeaker-v1.sh
sudo chmod +x /usr/local/bin/setup-respeaker-v1.sh

# Install Service
cp respeaker-setup.service /etc/systemd/system/respeaker-setup.service
sudo systemctl daemon-reload
sudo systemctl enable respeaker-setup.service
```
