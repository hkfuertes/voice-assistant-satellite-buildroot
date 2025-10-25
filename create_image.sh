#!/bin/bash
set -e

ROOTFS_DIR="${1:-./alpine-wyoming/rootfs}"
OUTPUT_IMG="${2:-alpine-wyoming-rpi0w2.img}"
IMG_SIZE="2G"

if [ ! -d "$ROOTFS_DIR" ]; then
    echo "ERROR: Rootfs directory not found: $ROOTFS_DIR"
    exit 1
fi

echo "==> Creating image file ($IMG_SIZE)..."
dd if=/dev/zero of="$OUTPUT_IMG" bs=1 count=0 seek=$IMG_SIZE

echo "==> Partitioning..."
parted -s "$OUTPUT_IMG" mklabel msdos
parted -s "$OUTPUT_IMG" mkpart primary fat32 1MiB 257MiB
parted -s "$OUTPUT_IMG" mkpart primary ext4 257MiB 100%
parted -s "$OUTPUT_IMG" set 1 boot on

echo "==> Setting up loop device..."
LOOP_DEV=$(losetup -fP --show "$OUTPUT_IMG")
BOOT_DEV="${LOOP_DEV}p1"
ROOT_DEV="${LOOP_DEV}p2"

echo "==> Formatting partitions..."
mkfs.vfat -F 32 -n BOOT "$BOOT_DEV"
mkfs.ext4 -L rootfs "$ROOT_DEV"

echo "==> Mounting partitions..."
MOUNT_DIR=$(mktemp -d)
mkdir -p "$MOUNT_DIR/boot" "$MOUNT_DIR/root"
mount "$ROOT_DEV" "$MOUNT_DIR/root"
mount "$BOOT_DEV" "$MOUNT_DIR/boot"

echo "==> Copying rootfs..."
rsync -a --info=progress2 "$ROOTFS_DIR/" "$MOUNT_DIR/root/"

echo "==> Copying boot files..."
rsync -a --info=progress2 "$ROOTFS_DIR/boot/" "$MOUNT_DIR/boot/"

echo "==> Unmounting..."
umount "$MOUNT_DIR/boot"
umount "$MOUNT_DIR/root"
losetup -d "$LOOP_DEV"
rm -rf "$MOUNT_DIR"

echo ""
echo "==================================================================="
echo "Image created: $OUTPUT_IMG"
echo "Flash with: sudo dd if=$OUTPUT_IMG of=/dev/sdX bs=4M status=progress"
echo "==================================================================="
