#!/bin/bash
set -euo pipefail

ENV="${BASH_SOURCE[0]%/*}/.env"
FD="${BASH_SOURCE[0]%/*}/_files"

if [ ! -f "$ENV" ]; then
    echo "$ENV not found. Copy .env.example next to the script and fill it in"
    exit 1
fi

set -o allexport
source "$ENV"
source "$FD/.pkgs"
set +o allexport

read -rp "Root password: " RPW
read -rp "Password for $USERNAME: " UPW


if [ ! -b "$DISK" ]; then
    echo "$DISK does not exist. Select one from lsblk"
    exit 1
fi

if [ ! -d /sys/firmware/efi/efivars ]; then
    echo "Not in UEFI mode. Set UEFI mode on BIOS"
    exit 1
fi

if ! ping -c 1 -W 3 archlinux.org >/dev/null 2>&1; then
    echo "No internet. Plugin ethernet or use iwctl to connect to a network"
    exit 1
fi

if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    echo "multilib not enabled. Add it to /etc/pacman.conf"
    exit 1
fi

if ! grep -qE "^#?${LOCALE} " /etc/locale.gen; then
    echo "$LOCALE is not a valid locale"
    exit 1
fi

if [ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]; then
    echo "$TIMEZONE is not a valid timezone"
    exit 1
fi

# 1. Disk formatting
#   / -> ext4 [$ROOT_SIZE]
#   /boot -> fat32 [$BOOT_SIZE]\
#   /home -> ext4

wipefs -a "$DISK"
sgdisk --zap-all "$DISK"

sgdisk -n 1:0:+$BOOT_SIZE -t 1:ef00 -c 1:"EFI" "$DISK"
sgdisk -n 2:0:+$ROOT_SIZE -t 2:8300 -c 2:"root" "$DISK"
sgdisk -n 3:0:0 -t 3:8300 -c 3:"home" "$DISK"

ESP="${DISK}${DF}1"
ROOT="${DISK}${DF}2"
HOMED="${DISK}${DF}3"

mkfs.fat -F32 "$ESP"
mkfs.ext4 "$ROOT"
mkfs.ext4 "$HOMED"

# 2. Mount Disks
mkdir -p /mnt
mount "$ROOT" /mnt
mkdir -p /mnt/boot /mnt/home
mount "$ESP" /mnt/boot
mount "$HOMED" /mnt/home

# Pkg install
pacstrap -K /mnt $PKGS_CORE

genfstab -U /mnt >> /mnt/etc/fstab


# Basic setup
sed -i "s/^#$LOCALE/$LOCALE/" /mnt/etc/locale.gen
echo "LANG=$LOCALE" > /mnt/etc/locale.conf
echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf

echo "$HOSTNAME" > /mnt/etc/hostname
cat "$FD/hosts" | sed "s/\$HOSTNAME/$HOSTNAME/" >> /mnt/etc/hosts

mkdir -p /mnt/etc/systemd/network
cp "$FD/20-wired.network" /mnt/etc/systemd/network/20-wired.network

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers

arch-chroot /mnt <<CHR1_EOF
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
hwclock --systohc
locale-gen
echo "root:$RPW" | chpasswd
useradd -m -G wheel "$USERNAME"
echo "$USERNAME:$UPW" | chpasswd
visudo -c
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable iwd
CHR1_EOF

git clone "$REPO_URL" "/mnt/home/$USERNAME/repo"

arch-chroot /mnt <<CHR2_EOF
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/repo"
CHR2_EOF

cp "$FD/.pkgs" "/mnt/home/$USERNAME/.pkgs"


# Boot setup
UUID=$(blkid -s PARTUUID -o value "$ROOT")
sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /mnt/etc/mkinitcpio.conf

arch-chroot /mnt <<CHR3_EOF
mkinitcpio -P
bootctl install
CHR3_EOF

cp "$FD/loader.conf" /mnt/boot/loader/loader.conf
sed "s/\$UUID/$UUID/" "$FD/arch.conf" > /mnt/boot/loader/entries/arch.conf

# Finishing up
umount -R /mnt
reboot
