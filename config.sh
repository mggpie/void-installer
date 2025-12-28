#!/bin/sh
# Void Linux Installation Configuration

# System
TARGET_DISK="/dev/nvme0n1"  # auto-detected: nvme0n1 > vda > sda
HOSTNAME="here"
TIMEZONE="Europe/Warsaw"
LOCALE="en_US.UTF-8"
KEYMAP="pl"

# User
USERNAME="me"
USER_GROUPS="wheel audio video storage network input optical kvm lp"

# Disk
USE_SWAP="yes"
SWAP_SIZE="auto"  # or e.g. "8G"
FILESYSTEM="ext4"  # ext4, btrfs, xfs
USE_ENCRYPTION="yes"

# Boot
BOOTLOADER="grub"
BOOT_MODE="uefi"

# Network
NETWORK_MANAGER="dhcpcd"  # or NetworkManager
ENABLE_SSH="yes"
