#!/bin/sh
#
# Void Linux Automated Installation Script
# This script automates the Void Linux installation process
# Compatible with POSIX sh (dash)
#

set -e  # Exit on error

# Source configuration
if [ -f "$(dirname "$0")/config.sh" ]; then
    . "$(dirname "$0")/config.sh"
else
    # Default configuration if config.sh not found
    
    # Auto-detect target disk
    if [ -b "/dev/vda" ]; then
        # Virtual machine (QEMU/KVM with virtio)
        TARGET_DISK="/dev/vda"
    elif [ -b "/dev/nvme0n1" ]; then
        # Physical machine with NVMe
        TARGET_DISK="/dev/nvme0n1"
    elif [ -b "/dev/sda" ]; then
        # Physical/Virtual machine with SATA/SCSI
        TARGET_DISK="/dev/sda"
    else
        # Fallback - user will need to confirm
        TARGET_DISK="/dev/sda"
    fi
    
    HOSTNAME="here"
    TIMEZONE="Europe/Warsaw"
    LOCALE="en_US.UTF-8"
    KEYMAP="pl"
    USERNAME="me"
    USER_GROUPS="wheel audio video storage network input optical kvm lp"
    USE_SWAP="yes"
    SWAP_SIZE="auto"
    FILESYSTEM="ext4"
    USE_ENCRYPTION="yes"
    BOOTLOADER="grub"
    BOOT_MODE="uefi"
    NETWORK_MANAGER="dhcpcd"
    ENABLE_SSH="yes"
    DOTFILES_REPO="https://github.com/mggpie/dotfiles.git"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    log_error "Please run as root"
    exit 1
fi

# Check if running from Void Linux live ISO
if ! grep -q "void" /etc/os-release 2>/dev/null; then
    log_warn "This doesn't appear to be Void Linux. Continue anyway? (y/N)"
    read -r response
    case "$response" in
        [Yy]*) ;;
        *) exit 1 ;;
    esac
fi

log_info "Starting Void Linux automated installation..."
log_info "Target disk: $TARGET_DISK"
log_info "Hostname: $HOSTNAME"
log_info "Username: $USERNAME"
echo ""

# ============================================================================
# Collect all passwords upfront
# ============================================================================
log_info "Password Setup"
log_info "=============="
echo ""

# Collect LUKS encryption password
log_warn "Set disk encryption passphrase:"
stty -echo </dev/tty
printf "Enter passphrase: " >/dev/tty
read -r LUKS_PASSPHRASE </dev/tty
printf "\n" >/dev/tty
printf "Confirm passphrase: " >/dev/tty
read -r LUKS_PASSPHRASE_CONFIRM </dev/tty
printf "\n" >/dev/tty
stty echo </dev/tty

if [ "$LUKS_PASSPHRASE" != "$LUKS_PASSPHRASE_CONFIRM" ]; then
    log_error "Passphrases do not match!"
    exit 1
fi
echo ""

# Collect root password
log_warn "Set root password:"
stty -echo </dev/tty
printf "Enter root password: " >/dev/tty
read -r ROOT_PASSWORD </dev/tty
printf "\n" >/dev/tty
printf "Confirm root password: " >/dev/tty
read -r ROOT_PASSWORD_CONFIRM </dev/tty
printf "\n" >/dev/tty
stty echo </dev/tty

if [ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]; then
    log_error "Passwords do not match!"
    exit 1
fi
echo ""

# Collect user password
log_warn "Set password for user $USERNAME:"
stty -echo </dev/tty
printf "Enter password for %s: " "$USERNAME" >/dev/tty
read -r USER_PASSWORD </dev/tty
printf "\n" >/dev/tty
printf "Confirm password for %s: " "$USERNAME" >/dev/tty
read -r USER_PASSWORD_CONFIRM </dev/tty
printf "\n" >/dev/tty
stty echo </dev/tty

if [ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]; then
    log_error "Passwords do not match!"
    exit 1
fi
echo ""

log_info "All passwords collected. Starting installation..."
sleep 2
echo ""

# Clean up any existing LUKS mappings FIRST
log_info "Cleaning up any existing LUKS mappings..."
cryptsetup close voidcrypt 2>/dev/null || true
dmsetup remove voidcrypt 2>/dev/null || true
sync
sleep 1

# Ensure repository is configured and install required tools
log_info "Configuring repositories and installing tools..."
mkdir -p /etc/xbps.d
echo "repository=https://repo-default.voidlinux.org/current" > /etc/xbps.d/00-repository-main.conf
xbps-install -Suy xbps
xbps-install -Sy gptfdisk parted

# ============================================================================
# STEP 1: Partition the disk
# ============================================================================
log_info "Step 1: Partitioning disk $TARGET_DISK..."

# Wipe existing partition table and data
dd if=/dev/zero of="$TARGET_DISK" bs=1M count=100 2>/dev/null || true
wipefs -af "$TARGET_DISK" 2>/dev/null || true
sgdisk --zap-all "$TARGET_DISK" 2>/dev/null || true

# Create GPT partition table
sgdisk -o "$TARGET_DISK"

# Create EFI partition (512MB)
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" "$TARGET_DISK"

# Create boot partition (1GB)
sgdisk -n 2:0:+1G -t 2:8300 -c 2:"BOOT" "$TARGET_DISK"

# Create root partition (rest of disk)
sgdisk -n 3:0:0 -t 3:8300 -c 3:"ROOT" "$TARGET_DISK"

# Inform kernel of partition changes
sync
sleep 2

# Determine partition naming scheme
if echo "$TARGET_DISK" | grep -q "nvme\|mmcblk"; then
    PART1="${TARGET_DISK}p1"
    PART2="${TARGET_DISK}p2"
    PART3="${TARGET_DISK}p3"
else
    PART1="${TARGET_DISK}1"
    PART2="${TARGET_DISK}2"
    PART3="${TARGET_DISK}3"
fi

log_info "Created partitions: $PART1 (EFI), $PART2 (BOOT), $PART3 (ROOT)"

# ============================================================================
# STEP 2: Setup LUKS encryption
# ============================================================================
log_info "Step 2: Setting up LUKS encryption..."

# Close any existing LUKS mappings from previous runs
cryptsetup close voidcrypt 2>/dev/null || true
dmsetup remove voidcrypt 2>/dev/null || true
sync
sleep 1

# Wipe any existing LUKS header
dd if=/dev/zero of="$PART3" bs=1M count=10 2>/dev/null || true
sync
sleep 1

# Format and open LUKS partition (using password collected at start)
log_info "Encrypting partition..."
printf "%s" "$LUKS_PASSPHRASE" | cryptsetup -q luksFormat --type luks2 -s 512 "$PART3"

log_info "Opening encrypted partition..."
printf "%s" "$LUKS_PASSPHRASE" | cryptsetup luksOpen "$PART3" voidcrypt

# ============================================================================
# STEP 3: Create filesystems
# ============================================================================
log_info "Step 3: Creating filesystems..."

# Format EFI partition
mkfs.vfat -F32 -n EFI "$PART1"

# Format boot partition
mkfs.ext4 -L BOOT "$PART2"

# Format encrypted root partition
mkfs.ext4 -L ROOT /dev/mapper/voidcrypt

# Create swap file if enabled (on encrypted partition)
if [ "$USE_SWAP" = "yes" ]; then
    log_info "Swap will be created as a file after system installation"
fi

# ============================================================================
# STEP 4: Mount filesystems
# ============================================================================
log_info "Step 4: Mounting filesystems..."

mount /dev/mapper/voidcrypt /mnt
mkdir -p /mnt/boot
mount "$PART2" /mnt/boot
mkdir -p /mnt/boot/efi
mount "$PART1" /mnt/boot/efi

# ============================================================================
# STEP 5: Install base system
# ============================================================================
log_info "Step 5: Installing base system..."

# Ensure we have the latest xbps
xbps-install -Suy xbps

# Import Void Linux RSA keys to avoid prompts
log_info "Importing Void Linux repository keys..."
mkdir -p /mnt/var/db/xbps/keys
cp -a /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

# Install base system (microcode will be installed later via Ansible)
BASE_PACKAGES="base-system grub-x86_64-efi efibootmgr cryptsetup lvm2 linux linux-firmware curl git micro sudo binutils"

# Add VM-specific packages if running in a VM
if [ "$TARGET_DISK" = "/dev/vda" ]; then
    BASE_PACKAGES="$BASE_PACKAGES openssh spice-vdagent"
fi

# Add selected network manager
if [ "$NETWORK_MANAGER" = "NetworkManager" ]; then
    BASE_PACKAGES="$BASE_PACKAGES NetworkManager"
else
    BASE_PACKAGES="$BASE_PACKAGES dhcpcd"
fi

log_info "Installing packages: $BASE_PACKAGES"
XBPS_ARCH=x86_64 xbps-install -y -Sy -R https://repo-default.voidlinux.org/current -r /mnt $BASE_PACKAGES

# ============================================================================
# STEP 6: Configure the system
# ============================================================================
log_info "Step 6: Configuring the system..."

# Set hostname
echo "$HOSTNAME" > /mnt/etc/hostname

# Configure hosts file
cat > /mnt/etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# Set timezone
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime

# Set locale
echo "LANG=$LOCALE" > /mnt/etc/locale.conf
echo "$LOCALE UTF-8" >> /mnt/etc/default/libc-locales
chroot /mnt xbps-reconfigure -f glibc-locales

# Set keyboard layout
echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf

# Configure fstab
log_info "Generating fstab..."
EFI_UUID=$(blkid -s UUID -o value "$PART1")
BOOT_UUID=$(blkid -s UUID -o value "$PART2")

cat > /mnt/etc/fstab << EOF
# /etc/fstab: static file system information
#
# <file system> <mount point> <type> <options> <dump> <pass>
/dev/mapper/voidcrypt /         ext4  defaults,noatime  0 1
UUID=$BOOT_UUID       /boot     ext4  defaults,noatime  0 2
UUID=$EFI_UUID        /boot/efi vfat  defaults,noatime  0 2
tmpfs                 /tmp      tmpfs defaults,nosuid,nodev 0 0
EOF

# Configure crypttab
ROOT_UUID=$(blkid -s UUID -o value "$PART3")
echo "voidcrypt UUID=$ROOT_UUID none luks" > /mnt/etc/crypttab

# Configure dracut for LUKS
mkdir -p /mnt/etc/dracut.conf.d
cat > /mnt/etc/dracut.conf.d/10-crypt.conf << EOF
add_dracutmodules+=" crypt dm rootfs-block "
install_items+=" /etc/crypttab "
EOF

# ============================================================================
# STEP 7: Install and configure GRUB
# ============================================================================
log_info "Step 7: Installing GRUB..."

# Configure GRUB for encrypted root
cat > /mnt/etc/default/grub << EOF
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="Void"
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4 quiet"
GRUB_CMDLINE_LINUX="rd.luks.uuid=$ROOT_UUID rd.lvm=0"
GRUB_ENABLE_CRYPTODISK=y
EOF

# Chroot and install GRUB
mount --rbind /sys /mnt/sys
mount --rbind /dev /mnt/dev
mount --rbind /proc /mnt/proc

chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Void" --recheck
chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# ============================================================================
# STEP 8: Create user and set passwords
# ============================================================================
log_info "Step 8: Creating user and setting passwords..."

# Set root password (using password collected at start)
# Hash the password using openssl and set it with usermod
ROOT_HASH=$(printf '%s\n' "$ROOT_PASSWORD" | openssl passwd -6 -stdin)
chroot /mnt usermod -p "$ROOT_HASH" root

# Create user
chroot /mnt useradd -m -G wheel,audio,video,storage,network,input,optical,kvm,lp -s /bin/sh "$USERNAME"

# Set user password (using password collected at start)
# Hash the password using openssl and set it with usermod
USER_HASH=$(printf '%s\n' "$USER_PASSWORD" | openssl passwd -6 -stdin)
chroot /mnt usermod -p "$USER_HASH" "$USERNAME"

# Configure sudo
echo "%wheel ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/wheel
chmod 0440 /mnt/etc/sudoers.d/wheel

# ============================================================================
# STEP 9: Enable services
# ============================================================================
log_info "Step 9: Enabling services..."

# Enable network service
if [ "$NETWORK_MANAGER" = "NetworkManager" ]; then
    chroot /mnt ln -sf /etc/sv/NetworkManager /etc/runit/runsvdir/default/
else
    chroot /mnt ln -sf /etc/sv/dhcpcd /etc/runit/runsvdir/default/
fi

# Enable SSH if configured
if [ "$ENABLE_SSH" = "yes" ]; then
    chroot /mnt ln -sf /etc/sv/sshd /etc/runit/runsvdir/default/
fi

# Enable spice-vdagent if in VM
if [ "$TARGET_DISK" = "/dev/vda" ]; then
    chroot /mnt ln -sf /etc/sv/spice-vdagentd /etc/runit/runsvdir/default/
fi

# ============================================================================
# STEP 10: Create swap file (if enabled)
# ============================================================================
if [ "$USE_SWAP" = "yes" ]; then
    log_info "Step 10: Creating swap file..."
    
    # Determine swap size
    if [ "$SWAP_SIZE" = "auto" ]; then
        # Get RAM size in GB
        RAM_GB=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
        SWAP_SIZE="${RAM_GB}G"
    fi
    
    # Create swap file
    chroot /mnt fallocate -l "$SWAP_SIZE" /swapfile
    chroot /mnt chmod 600 /swapfile
    chroot /mnt mkswap /swapfile
    
    # Add to fstab
    echo "/swapfile none swap sw 0 0" >> /mnt/etc/fstab
    
    log_info "Created ${SWAP_SIZE} swap file"
fi

# ============================================================================
# STEP 11: Reconfigure all packages
# ============================================================================
log_info "Step 11: Reconfiguring all packages..."

chroot /mnt xbps-reconfigure -fa

# ============================================================================
# STEP 12: Final steps
# ============================================================================
log_info "Step 12: Final configuration..."

# Unmount filesystems
log_info "Unmounting filesystems..."
umount -R /mnt

# Clear passwords from memory
unset LUKS_PASSPHRASE ROOT_PASSWORD USER_PASSWORD
unset LUKS_PASSPHRASE_CONFIRM ROOT_PASSWORD_CONFIRM USER_PASSWORD_CONFIRM

log_info "============================================"
log_info "Installation complete!"
log_info "============================================"
echo ""
log_info "Your Void Linux system is ready!"
log_info ""
log_info "Next steps after reboot:"
log_info "  1. Enter LUKS passphrase at boot"
log_info "  2. Login as: $USERNAME"
log_info "  3. Run Ansible playbook to configure system"
echo ""
log_info "Rebooting in 5 seconds..."
sleep 5
reboot
