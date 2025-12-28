#!/bin/sh
#
# Void Linux Installation Configuration
# Edit this file to customize your installation
#

# ============================================================================
# System Configuration
# ============================================================================

# Target disk for installation (WARNING: will be erased!)
# Detected: nvme0n1 (465.8G)
TARGET_DISK="/dev/nvme0n1"

# Hostname
HOSTNAME="here"

# Timezone (see /usr/share/zoneinfo/)
TIMEZONE="Europe/Warsaw"

# Locale
LOCALE="en_US.UTF-8"

# Keyboard layout
KEYMAP="pl"

# ============================================================================
# User Configuration
# ============================================================================

# Username for primary user
USERNAME="me"

# Additional groups for the user (space-separated)
USER_GROUPS="wheel audio video storage network input optical kvm lp"

# ============================================================================
# Disk Configuration
# ============================================================================

# Swap configuration
# Set to "yes" to create a swap file, "no" to skip
USE_SWAP="yes"

# Swap size (e.g., "8G", "16G", or "auto" for RAM size)
# For desktop systems without hibernate, you may set this to "no" or smaller size
SWAP_SIZE="auto"

# Filesystem type for root partition
# Options: ext4, btrfs, xfs
FILESYSTEM="ext4"

# LUKS encryption (always enabled in this setup)
# The script will prompt for passphrase during installation
USE_ENCRYPTION="yes"

# ============================================================================
# Bootloader Configuration
# ============================================================================

# Bootloader type (only GRUB supported currently)
BOOTLOADER="grub"

# Boot mode (uefi or bios)
BOOT_MODE="uefi"

# ============================================================================
# Network Configuration
# ============================================================================

# Network manager: dhcpcd or NetworkManager
# Note: WiFi configuration will be done via Ansible post-install
NETWORK_MANAGER="dhcpcd"

# Enable SSH daemon
ENABLE_SSH="yes"

# ============================================================================
# Additional Packages
# ============================================================================

# Minimal base packages (always installed):
# - base-system
# - linux
# - linux-firmware
# - grub
# - cryptsetup
# - NetworkManager/dhcpcd
# - curl, wget, git, vim, sudo
#
# All other packages will be installed via Ansible after first boot

# ============================================================================
# Post-Installation
# ============================================================================

# Dotfiles repository

# Run Ansible playbook after installation (manual step)
# The script will create a helper script for post-install setup
