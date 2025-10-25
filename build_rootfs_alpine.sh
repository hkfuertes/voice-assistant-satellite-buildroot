#!/bin/bash
set -e

ARCH="aarch64"
ALPINE_MIRROR="https://dl-cdn.alpinelinux.org/alpine"
ALPINE_BRANCH="v3.20"
OUTPUT_DIR="${1:-./alpine-wyoming}"
ROOTFS="$OUTPUT_DIR/rootfs"

echo "==> Cleaning previous build..."
rm -rf "$OUTPUT_DIR"

echo "==> Creating directory structure..."
mkdir -p "$OUTPUT_DIR" "$ROOTFS"

if ! which qemu-aarch64-static >/dev/null 2>&1; then
    echo "ERROR: qemu-user-static not found"
    echo "Install: apt install qemu-user-static binfmt-support"
    exit 1
fi

if [ ! -f "$OUTPUT_DIR/apk.static" ]; then
    echo "==> Downloading apk.static..."
    wget -O "$OUTPUT_DIR/apk.static" \
        "https://gitlab.alpinelinux.org/api/v4/projects/5/packages/generic/v2.14.6/$ARCH/apk.static"
    chmod +x "$OUTPUT_DIR/apk.static"
fi

echo "==> Bootstrapping Alpine Linux..."
"$OUTPUT_DIR/apk.static" \
    --arch "$ARCH" \
    -X "$ALPINE_MIRROR/$ALPINE_BRANCH/main" \
    -X "$ALPINE_MIRROR/$ALPINE_BRANCH/community" \
    -U --allow-untrusted \
    --root "$ROOTFS" \
    --no-scripts \
    --initdb add \
    alpine-base linux-rpi raspberrypi-bootloader \
    iwd alsa-utils shadow sed coreutils \
    python3 py3-pip py3-virtualenv git \
    gcc g++ make musl-dev python3-dev \
    libgpiod-dev swig openblas-dev linux-headers \
    openssh-server chrony nano \
    parted e2fsprogs-extra

echo "==> Setting up QEMU..."
mkdir -p "$ROOTFS/usr/bin"
cp "$(which qemu-aarch64-static)" "$ROOTFS/usr/bin/"

cat > "$ROOTFS/etc/apk/repositories" <<EOF
$ALPINE_MIRROR/$ALPINE_BRANCH/main
$ALPINE_MIRROR/$ALPINE_BRANCH/community
EOF

cat > "$ROOTFS/etc/fstab" <<'EOF'
/dev/mmcblk0p1  /boot           vfat    defaults        0       2
/dev/mmcblk0p2  /               ext4    defaults        0       1
EOF

echo "wyoming-sat" > "$ROOTFS/etc/hostname"
cat > "$ROOTFS/etc/hosts" <<'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   wyoming-sat
EOF

mkdir -p "$ROOTFS/etc/iwd"
cat > "$ROOTFS/etc/iwd/main.conf" <<'EOF'
[General]
EnableNetworkConfiguration=true
UseDefaultInterface=true

[Network]
NameResolvingService=resolvconf
EnableIPv6=true
EOF

cat > "$ROOTFS/etc/network/interfaces" <<'EOF'
auto lo
iface lo inet loopback

auto wlan0
iface wlan0 inet dhcp
    hostname wyoming-sat
EOF

mkdir -p "$ROOTFS/usr/local/bin"
cat > "$ROOTFS/usr/local/bin/setup-wifi-from-boot.sh" <<'EOF'
#!/bin/sh
IWD_DIR="/var/lib/iwd"
mkdir -p "$IWD_DIR"
if ls /boot/*.psk >/dev/null 2>&1; then
    echo "Setting up WiFi..."
    mv /boot/*.psk "$IWD_DIR/"
    chmod 600 "$IWD_DIR"/*.psk
fi
EOF
chmod +x "$ROOTFS/usr/local/bin/setup-wifi-from-boot.sh"

cat > "$ROOTFS/usr/local/bin/setup-respeaker-v1.sh" <<'EOF'
#!/bin/sh
CARD="wm8960soundcard"
sleep 2
amixer -c "$CARD" sset 'Capture' 100% unmute cap 2>/dev/null
amixer -c "$CARD" sset 'ADC PCM' 195 2>/dev/null
amixer -c "$CARD" sset 'Left Input Mixer Boost' on 2>/dev/null
amixer -c "$CARD" sset 'Right Input Mixer Boost' on 2>/dev/null
amixer -c "$CARD" sset 'Left Input PGA Boost' on 2>/dev/null
amixer -c "$CARD" sset 'Right Input PGA Boost' on 2>/dev/null
amixer -c "$CARD" sset 'Left Input' 'MIC2' 2>/dev/null
amixer -c "$CARD" sset 'Right Input' 'MIC2' 2>/dev/null
amixer -c "$CARD" sset 'Playback' 100% unmute 2>/dev/null
amixer -c "$CARD" sset 'Speaker' 100% unmute 2>/dev/null
alsactl store 2>/dev/null
EOF
chmod +x "$ROOTFS/usr/local/bin/setup-respeaker-v1.sh"

cat > "$ROOTFS/usr/local/bin/expand-rootfs.sh" <<'EOF'
#!/bin/sh
set -e
ROOT_PART="/dev/mmcblk0p2"
ROOT_DEV="/dev/mmcblk0"

echo "Expanding root partition..."
parted -s "$ROOT_DEV" resizepart 2 100%
resize2fs "$ROOT_PART"

rc-update del expand-rootfs boot
rm -f /etc/init.d/expand-rootfs
rm -f /usr/local/bin/expand-rootfs.sh
echo "Root filesystem expanded successfully"
EOF
chmod +x "$ROOTFS/usr/local/bin/expand-rootfs.sh"

cat > "$ROOTFS/etc/asound.conf" <<'EOF'
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

mkdir -p "$ROOTFS/boot"
cat > "$ROOTFS/boot/config.txt" <<'EOF'
dtparam=spi=on
dtparam=i2c_arm=on
dtoverlay=wm8960-soundcard
dtoverlay=disable-wifi-power-save
EOF

cat > "$ROOTFS/boot/cmdline.txt" <<'EOF'
modules=loop,squashfs,sd-mod,usb-storage quiet console=tty1
EOF

echo "==> Creating services..."
cat > "$ROOTFS/etc/init.d/expand-rootfs" <<'EOF'
#!/sbin/openrc-run

description="Expand root filesystem on first boot"
depend() {
    need localmount
}

start() {
    ebegin "Expanding root filesystem"
    /usr/local/bin/expand-rootfs.sh
    eend $?
}
EOF
chmod +x "$ROOTFS/etc/init.d/expand-rootfs"

cat > "$ROOTFS/etc/init.d/wifi-setup" <<'EOF'
#!/sbin/openrc-run
description="Setup WiFi from boot partition"
depend() {
    need localmount
    before iwd
}
start() {
    ebegin "Configuring WiFi"
    /usr/local/bin/setup-wifi-from-boot.sh
    eend $?
}
EOF
chmod +x "$ROOTFS/etc/init.d/wifi-setup"

cat > "$ROOTFS/etc/init.d/respeaker-setup" <<'EOF'
#!/sbin/openrc-run
description="ReSpeaker 2-Mic HAT v1"
depend() {
    need localmount
    after alsasound
}
start() {
    ebegin "Configuring ReSpeaker"
    /usr/local/bin/setup-respeaker-v1.sh
    eend $?
}
EOF
chmod +x "$ROOTFS/etc/init.d/respeaker-setup"

cat > "$ROOTFS/etc/init.d/wyoming-satellite" <<'EOF'
#!/sbin/openrc-run
description="Wyoming Satellite"
command="/opt/wyoming/satellite/.venv/bin/python3"
command_args="/opt/wyoming/satellite/script/run \
  --name 'AssistPi' \
  --uri 'tcp://0.0.0.0:10700' \
  --mic-command 'arecord -D plughw:CARD=wm8960soundcard,DEV=0 -r 16000 -c 1 -f S16_LE -t raw' \
  --snd-command 'aplay -D plughw:CARD=wm8960soundcard,DEV=0 -r 22050 -c 1 -f S16_LE -t raw' \
  --wake-uri 'tcp://127.0.0.1:10400' \
  --wake-word-name 'ok_nabu' \
  --event-uri 'tcp://127.0.0.1:10500'"
command_background=true
pidfile="/run/${RC_SVCNAME}.pid"
directory="/opt/wyoming/satellite"
depend() {
    need net
    after iwd respeaker-setup wyoming-openwakeword wyoming-2mic-leds
}
EOF
chmod +x "$ROOTFS/etc/init.d/wyoming-satellite"

cat > "$ROOTFS/etc/init.d/wyoming-openwakeword" <<'EOF'
#!/sbin/openrc-run
description="Wyoming OpenWakeWord"
command="/opt/wyoming/openwakeword/.venv/bin/python3"
command_args="/opt/wyoming/openwakeword/script/run --uri 'tcp://127.0.0.1:10400'"
command_background=true
pidfile="/run/${RC_SVCNAME}.pid"
directory="/opt/wyoming/openwakeword"
depend() {
    need net
}
EOF
chmod +x "$ROOTFS/etc/init.d/wyoming-openwakeword"

cat > "$ROOTFS/etc/init.d/wyoming-2mic-leds" <<'EOF'
#!/sbin/openrc-run
description="2Mic LEDs"
command="/opt/wyoming/satellite/.venv/bin/python3"
command_args="/opt/wyoming/satellite/examples/2mic_service.py --uri 'tcp://127.0.0.1:10500' --led-brightness 10"
command_background=true
pidfile="/run/${RC_SVCNAME}.pid"
directory="/opt/wyoming/satellite/examples"
depend() {
    need net
}
EOF
chmod +x "$ROOTFS/etc/init.d/wyoming-2mic-leds"

cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf"

echo "==> Mounting filesystems..."
mount -t proc none "$ROOTFS/proc"
mount -t sysfs none "$ROOTFS/sys"
mount -o bind /dev "$ROOTFS/dev"
mount -t devpts none "$ROOTFS/dev/pts"

echo "==> Running APK triggers..."
chroot "$ROOTFS" /bin/sh -c 'apk fix --no-scripts || true'

echo "==> Installing Wyoming..."
chroot "$ROOTFS" /bin/sh <<'CHROOT'
echo "root:alpine" | chpasswd
rc-update add devfs sysinit
rc-update add dmesg sysinit
rc-update add mdev sysinit
rc-update add hwdrivers sysinit
rc-update add modules boot
rc-update add hwclock boot
rc-update add swap boot
rc-update add hostname boot
rc-update add sysctl boot
rc-update add bootmisc boot
rc-update add syslog boot
rc-update add networking boot
rc-update add expand-rootfs boot
rc-update add iwd default
rc-update add chronyd default
rc-update add sshd default
rc-update add crond default
rc-update add local default
rc-update add wifi-setup boot
rc-update add respeaker-setup boot

mkdir -p /opt/wyoming
git clone https://github.com/rhasspy/wyoming-satellite.git /opt/wyoming/satellite
cd /opt/wyoming/satellite
git checkout 13bb0249310391bb7b7f6e109ddcc0d7d76223c1
script/setup
.venv/bin/pip3 install spidev gpiozero

git clone https://github.com/rhasspy/wyoming-openwakeword.git /opt/wyoming/openwakeword
cd /opt/wyoming/openwakeword
script/setup
sed -i 's/_MODULE = _PROGRAM_DIR.name.replace("-", "_")/_MODULE = "wyoming_openwakeword"/' script/run

rc-update add wyoming-openwakeword default
rc-update add wyoming-2mic-leds default
rc-update add wyoming-satellite default
CHROOT

echo "==> Cleaning up..."
rm -f "$ROOTFS/etc/resolv.conf"
umount "$ROOTFS/dev/pts"
umount "$ROOTFS/dev"
umount "$ROOTFS/sys"
umount "$ROOTFS/proc"
rm -f "$ROOTFS/usr/bin/qemu-aarch64-static"

cat > "$OUTPUT_DIR/MyNetwork.psk.example" <<'EOF'
[Security]
PreSharedKey=your_wifi_password_here

[Settings]
AutoConnect=true
EOF

echo ""
echo "==================================================================="
echo "DONE - Wyoming Satellite PRE-INSTALLED"
echo "Rootfs: $ROOTFS"
echo "WiFi: Copy *.psk files to /boot with SSID as filename"
echo "First boot will auto-expand rootfs to use full SD card"
echo "==================================================================="
