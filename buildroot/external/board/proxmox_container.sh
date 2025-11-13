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

#############################################################################
# LxC does not have eudev, so we need to create a custom PulseAudio system.pa
# to load the correct modules and set up the audio devices.
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