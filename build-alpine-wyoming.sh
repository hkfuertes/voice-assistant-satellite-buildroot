#!/bin/bash
set -euo pipefail

# Configuration
ALPINE_MIRROR="http://dl-cdn.alpinelinux.org/alpine"
ALPINE_BRANCH="v3.22"
ALPINE_ARCH="aarch64"
OUTPUT_IMG="alpine-wyoming-rpi.img"
IMG_SIZE="2G"
HOSTNAME="wyoming-pi"
ROOT_PASSWORD="alpine"

# Temporary directories
WORK_DIR=$(mktemp -d)
MOUNT_BOOT="${WORK_DIR}/boot"
MOUNT_ROOT="${WORK_DIR}/root"
ROOTFS="${WORK_DIR}/rootfs"

cleanup() {
    echo "[INFO] Cleaning up resources..."
    umount "$MOUNT_BOOT" 2>/dev/null || true
    umount "$MOUNT_ROOT" 2>/dev/null || true
    losetup -d "$LOOP_DEV" 2>/dev/null || true
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo "[STEP 1/12] Downloading apk-tools-static..."
wget -q -O "${WORK_DIR}/apk.static" \
    "https://gitlab.alpinelinux.org/api/v4/projects/5/packages/generic/v2.14.4/x86_64/apk.static"
chmod +x "${WORK_DIR}/apk.static"

echo "[STEP 2/12] Creating Alpine base system ${ALPINE_BRANCH}..."
mkdir -p "$ROOTFS"
"${WORK_DIR}/apk.static" \
    -X "${ALPINE_MIRROR}/${ALPINE_BRANCH}/main" \
    -U --allow-untrusted --root "$ROOTFS" --initdb \
    add alpine-base alpine-baselayout-data

echo "[STEP 3/12] Configuring repositories..."
cat > "${ROOTFS}/etc/apk/repositories" <<EOF
${ALPINE_MIRROR}/${ALPINE_BRANCH}/main
${ALPINE_MIRROR}/${ALPINE_BRANCH}/community
EOF

echo "[STEP 4/12] Installing system packages..."
chroot "$ROOTFS" /sbin/apk --no-cache add \
    linux-rpi \
    raspberrypi-bootloader \
    openssh \
    sudo \
    tzdata \
    git \
    python3 \
    py3-pip \
    py3-virtualenv \
    alsa-utils \
    alsa-lib \
    alsa-utils-openrc

echo "[STEP 5/12] Installing build dependencies..."
chroot "$ROOTFS" /sbin/apk --no-cache add \
    python3-dev \
    gcc \
    musl-dev \
    linux-headers

echo "[STEP 6/12] Installing Wyoming Satellite..."
chroot "$ROOTFS" /bin/sh <<'CHROOT_SCRIPT'
# Create wyoming user
adduser -D -h /opt/wyoming -s /bin/sh wyoming
echo "wyoming:wyoming" | chpasswd

# Clone Wyoming Satellite
cd /opt/wyoming
su - wyoming -c "git clone https://github.com/rhasspy/wyoming-satellite.git"
cd wyoming-satellite

# Create venv and install dependencies
su - wyoming -c "python3 -m venv /opt/wyoming/venv"
su - wyoming -c "/opt/wyoming/venv/bin/pip3 install --upgrade pip wheel setuptools"
su - wyoming -c "/opt/wyoming/venv/bin/pip3 install -r requirements.txt"
su - wyoming -c "/opt/wyoming/venv/bin/pip3 install rpi-lgpio spidev"

# Copy LED service
cp -r examples /opt/wyoming/
chown -R wyoming:wyoming /opt/wyoming
CHROOT_SCRIPT

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

echo "[STEP 8/12] Creating Wyoming Satellite service (OpenRC)..."
cat > "${ROOTFS}/etc/init.d/wyoming-satellite" <<'EOF'
#!/sbin/openrc-run

name="Wyoming Satellite"
description="Wyoming Voice Satellite Service"

command="/opt/wyoming/venv/bin/python3"
command_args="/opt/wyoming/wyoming-satellite/script/run \
    --name ${HOSTNAME:-wyoming-pi} \
    --uri tcp://0.0.0.0:10700 \
    --mic-command 'arecord -D plughw:CARD=wm8960soundcard,DEV=0 -r 16000 -c 1 -f S16_LE -t raw' \
    --snd-command 'aplay -D plughw:CARD=wm8960soundcard,DEV=0 -r 22050 -c 1 -f S16_LE -t raw' \
    --wake-uri tcp://localhost:10400 \
    --wake-word-name ok_nabu \
    --event-uri tcp://localhost:10500"

command_user="wyoming:wyoming"
command_background=true
pidfile="/run/wyoming-satellite.pid"

depend() {
    need net
    after firewall
}
EOF

echo "[STEP 9/12] Creating LED service (OpenRC)..."
cat > "${ROOTFS}/etc/init.d/wyoming-2mic-leds" <<'EOF'
#!/sbin/openrc-run

name="Wyoming 2Mic LEDs"
description="ReSpeaker 2-Mic HAT LED Control Service"

command="/opt/wyoming/venv/bin/python3"
command_args="/opt/wyoming/examples/2mic_service.py \
    --uri tcp://0.0.0.0:10500 \
    --led-brightness 10"

command_user="wyoming:wyoming"
command_background=true
pidfile="/run/wyoming-leds.pid"

depend() {
    need net
}
EOF

chmod +x "${ROOTFS}/etc/init.d/wyoming-satellite"
chmod +x "${ROOTFS}/etc/init.d/wyoming-2mic-leds"

echo "[STEP 10/12] Configuring system..."
# Hostname
echo "$HOSTNAME" > "${ROOTFS}/etc/hostname"

# Root password
chroot "$ROOTFS" /bin/sh -c "echo 'root:${ROOT_PASSWORD}' | chpasswd"

# Enable services
chroot "$ROOTFS" /sbin/rc-update add sshd default
chroot "$ROOTFS" /sbin/rc-update add wyoming-satellite default
chroot "$ROOTFS" /sbin/rc-update add wyoming-2mic-leds default
chroot "$ROOTFS" /sbin/rc-update add alsa default

# Network configuration
cat > "${ROOTFS}/etc/network/interfaces" <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto wlan0
iface wlan0 inet dhcp
EOF

# Configure timezone
chroot "$ROOTFS" /bin/sh -c "ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime"

echo "[STEP 11/12] Creating disk image ${IMG_SIZE}..."
dd if=/dev/zero of="$OUTPUT_IMG" bs=1 count=0 seek="$IMG_SIZE" 2>/dev/null

# Create partition table
parted -s "$OUTPUT_IMG" mklabel msdos
parted -s "$OUTPUT_IMG" mkpart primary fat32 1MiB 256MiB
parted -s "$OUTPUT_IMG" mkpart primary ext4 256MiB 100%
parted -s "$OUTPUT_IMG" set 1 boot on

# Mount image with loop device
LOOP_DEV=$(losetup -fP --show "$OUTPUT_IMG")
sleep 2

# Format partitions
mkfs.vfat -F 32 -n BOOT "${LOOP_DEV}p1"
mkfs.ext4 -F -L rootfs "${LOOP_DEV}p2"

# Mount partitions
mkdir -p "$MOUNT_BOOT" "$MOUNT_ROOT"
mount "${LOOP_DEV}p1" "$MOUNT_BOOT"
mount "${LOOP_DEV}p2" "$MOUNT_ROOT"

echo "[STEP 12/12] Copying filesystem..."
# Copy boot files
cp -r "${ROOTFS}/boot/"* "$MOUNT_BOOT/"

# Copy rootfs
rsync -a --exclude='/boot' "${ROOTFS}/" "$MOUNT_ROOT/"

# Configure fstab
cat > "${MOUNT_ROOT}/etc/fstab" <<EOF
/dev/mmcblk0p1  /boot  vfat  defaults          0  2
/dev/mmcblk0p2  /      ext4  defaults,noatime  0  1
EOF

# Sync and unmount
sync

echo ""
echo "==================================================================="
echo "Alpine Linux image created successfully"
echo "==================================================================="
echo ""
echo "Output file: $OUTPUT_IMG"
echo "Size: $IMG_SIZE"
echo "Alpine version: ${ALPINE_BRANCH}"
echo "Architecture: ${ALPINE_ARCH}"
echo ""
echo "To flash to SD card:"
echo "  sudo dd if=$OUTPUT_IMG of=/dev/sdX bs=4M status=progress conv=fsync"
echo ""
echo "Login credentials:"
echo "  Username: root"
echo "  Password: $ROOT_PASSWORD"
echo ""
echo "SSH access:"
echo "  ssh root@${HOSTNAME}.local"
echo ""
echo "Installed services:"
echo "  - Wyoming Satellite (port 10700)"
echo "  - Wyoming 2-Mic LEDs (port 10500)"
echo "  - ReSpeaker 2-Mic HAT (wm8960-soundcard)"
echo ""
echo "Next steps:"
echo "  1. Flash the image to SD card"
echo "  2. Insert into Raspberry Pi Zero 2W"
echo "  3. Connect to network (Ethernet or WiFi)"
echo "  4. Configure Home Assistant to connect to the satellite"
echo "==================================================================="
