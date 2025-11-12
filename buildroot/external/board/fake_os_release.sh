#!/bin/bash
set -e

###############################################################################
# Post-build script: Override /etc/os-release for LXC compatibility
# Usage: BR2_ROOTFS_POST_BUILD_SCRIPT="board/post-build-os-release.sh"
###############################################################################

TARGET_DIR="${1}"

if [ -z "${TARGET_DIR}" ]; then
    echo "ERROR: TARGET_DIR not provided"
    exit 1
fi

OS_RELEASE="${TARGET_DIR}/etc/os-release"

echo "========================================"
echo "Post-build: Override os-release"
echo "========================================"
echo "Target: ${OS_RELEASE}"
echo

# Backup del original (opcional)
if [ -f "${OS_RELEASE}" ]; then
    echo "Backing up original os-release..."
    cp "${OS_RELEASE}" "${OS_RELEASE}.buildroot-original"
fi

# Sobrescribir con versión compatible con Proxmox LXC
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

# Crear symlink estándar si no existe
if [ ! -e "${TARGET_DIR}/etc/lsb-release" ]; then
    echo "Creating lsb-release symlink..."
    ln -sf os-release "${TARGET_DIR}/etc/lsb-release"
fi

# Verificar permisos
chmod 644 "${OS_RELEASE}"

echo "[+] os-release updated successfully"
echo
echo "New content:"
cat "${OS_RELEASE}"
echo
echo "========================================"
