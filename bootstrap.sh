#!/bin/sh
# Void Linux Installer Bootstrap
# Downloads and runs the installation script from GitHub Pages
#
# Usage: curl -sL https://mggpie.github.io/void-installer/bootstrap.sh | sh

set -e

BASE_URL="https://mggpie.github.io/void-installer"

echo "╔════════════════════════════════════════════╗"
echo "║       Void Linux Installer Bootstrap       ║"
echo "║          with LUKS2 Encryption             ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Download installer and config
echo "[INFO] Downloading installer scripts..."
curl -sSL "${BASE_URL}/install.sh" -o /tmp/install-void.sh
curl -sSL "${BASE_URL}/config.example.sh" -o /tmp/config.sh
chmod +x /tmp/install-void.sh

echo "[INFO] Starting installation..."
echo ""
/tmp/install-void.sh
