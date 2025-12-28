# Void Linux Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell: POSIX](https://img.shields.io/badge/Shell-POSIX-green.svg)](https://pubs.opengroup.org/onlinepubs/9699919799/)

Automated Void Linux installation script with **LUKS2 full disk encryption**, automatic disk detection, and UEFI support.

## Features

- 🔒 **Full Disk Encryption** - LUKS2 with secure passphrase
- ⚡ **Auto Detection** - NVMe, SATA, and VirtIO disks
- 🖥️ **UEFI Ready** - GPT partitioning with EFI System Partition
- 📜 **POSIX Compliant** - Works with any `/bin/sh`
- 🔧 **Configurable** - Customize hostname, user, timezone, filesystem

## Quick Start

Boot from [Void Linux live ISO](https://voidlinux.org/download/), connect to the internet, and run:

```sh
curl -sL https://mggpie.github.io/void-installer/bootstrap.sh | sh
```

Or with wget:

```sh
wget -qO- https://mggpie.github.io/void-installer/bootstrap.sh | sh
```

## What Happens

1. Downloads `install.sh` and `config.example.sh` to `/tmp`
2. Prompts for LUKS passphrase, root password, and user password
3. Partitions the disk (EFI + Boot + LUKS-encrypted root)
4. Installs minimal Void Linux base system
5. Configures GRUB bootloader with LUKS support
6. Creates user account and sets up sudo

## Configuration

Edit `config.example.sh` before installation to customize:

| Variable | Default | Description |
|----------|---------|-------------|
| `TARGET_DISK` | auto-detected | Target disk (nvme0n1 > vda > sda) |
| `HOSTNAME` | `here` | System hostname |
| `USERNAME` | `me` | Primary user account |
| `TIMEZONE` | `Europe/Warsaw` | System timezone |
| `FILESYSTEM` | `ext4` | Root filesystem (ext4, btrfs, xfs) |
| `SWAP_SIZE` | `auto` | Swap file size or "auto" for RAM size |
| `USE_ENCRYPTION` | `yes` | Enable LUKS encryption |

## Partition Layout

| Partition | Size | Type | Mount Point |
|-----------|------|------|-------------|
| EFI | 512 MB | FAT32 | `/boot/efi` |
| Boot | 1 GB | ext4 | `/boot` |
| Root | Remaining | LUKS2 + ext4 | `/` |

## What Gets Installed

- **Base:** Void Linux (glibc) with runit init
- **Bootloader:** GRUB with LUKS support
- **Networking:** dhcpcd
- **Utilities:** curl, wget, git, vim, sudo

This is a minimal installation. Add your packages and [dotfiles](https://github.com/mggpie/dotfiles) after first boot.

## Requirements

- Void Linux live ISO (glibc)
- UEFI-capable system
- Internet connection
- Target disk (will be **completely erased**)

## ⚠️ Warning

**All data on the target disk will be erased!** Make sure to backup important data before running the installer.

## License

[MIT](LICENSE)

## Related

- [dotfiles](https://github.com/mggpie/dotfiles) - My configuration files for Void Linux
