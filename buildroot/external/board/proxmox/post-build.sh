#!/bin/bash
set -e

###############################################################################
# Post-build script: Override /etc/os-release for LXC compatibility
# TARGET_DIR="${1}"

if [ -z "${TARGET_DIR}" ]; then
    echo "ERROR: TARGET_DIR not provided"
    exit 1
fi

OS_RELEASE="${TARGET_DIR}/etc/os-release"

echo "Writing new os-release..."
cat > "${OS_RELEASE}" <<'EOF'
NAME="Alpine Linux"
VERSION="3.19"
ID=alpine
VERSION_ID=3.19
PRETTY_NAME="Voice Assistant (Buildroot on LXC)"
HOME_URL="https://buildroot.org/"
BUG_REPORT_URL="https://buildroot.org/support.html"
EOF

if [ ! -e "${TARGET_DIR}/etc/lsb-release" ]; then
    echo "Creating lsb-release symlink..."
    ln -sf os-release "${TARGET_DIR}/etc/lsb-release"
fi

chmod 644 "${OS_RELEASE}"

###############################################################################
# LxC does not have eudev, so we need to create a custom PulseAudio system.pa
# to load the correct modules and set up the audio devices.
cat > /dev/null <<EOF
# arecord -l
**** List of CAPTURE Hardware Devices ****
card 0: M1A [EMEET OfficeCore M1A], device 0: USB Audio [USB Audio] # <----- Card 0 on Host --> controlC0, pcmC0D0c, pcmC0D0p
  Subdevices: 0/1
  Subdevice #0: subdevice #0
card 2: Generic_1 [HD-Audio Generic], device 0: ALC897 Analog [ALC897 Analog]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
card 2: Generic_1 [HD-Audio Generic], device 2: ALC897 Alt Analog [ALC897 Alt Analog]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
EOF

cat > /dev/null <<EOF
# eMeet (card 0 on host → card 0 on container)
lxc.cgroup2.devices.allow: c 116:* rwm
lxc.mount.entry: /dev/snd/controlC0 dev/snd/controlC0 none bind,optional,create=file
lxc.mount.entry: /dev/snd/pcmC0D0c dev/snd/pcmC0D0c none bind,optional,create=file
lxc.mount.entry: /dev/snd/pcmC0D0p dev/snd/pcmC0D0p none bind,optional,create=file
lxc.mount.entry: /dev/snd/timer dev/snd/timer none bind,optional,create=file

# Buttons and input devices
lxc.cgroup2.devices.allow: c 13:* rwm
lxc.mount.entry: /dev/input/event3 dev/input/event0 none bind,optional,create=file

# Leds
lxc.mount.entry: /sys/class/leds sys/class/leds none bind,create=dir,rw 0 0
EOF

echo "Creating PulseAudio system.pa for LXC..."
cat > "${TARGET_DIR}/etc/pulse/system.pa" <<'EOF'
#!/usr/bin/pulseaudio -nF

load-module module-device-restore
load-module module-stream-restore
load-module module-card-restore

load-module module-alsa-source device=hw:0,0
load-module module-alsa-sink device=hw:0,0

load-module module-native-protocol-unix auth-anonymous=1
load-module module-default-device-restore
load-module module-always-sink
load-module module-suspend-on-idle
load-module module-position-event-sounds
EOF