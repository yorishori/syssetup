#!/bin/bash
set -euo pipefail

ENV="${BASH_SOURCE[0]%/*}/.env"
PKGFILE="${BASH_SOURCE[0]%/*}/.pkgs"
FD="${BASH_SOURCE[0]%/*}/_installfiles"

if [ ! -f "$ENV" ]; then
    echo "$ENV not found."
    exit 1
fi

set -o allexport
source "$ENV"
source "$PKGFILE"
set +o allexport

read -rp "Root password: " RPW
read -rp "Password for $USERNAME: " UPW

# 0. Check variables
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
umount -R /mnt 2>/dev/null || true
lsblk "$DISK"
read -rp "ALL DATA on $DISK will be destroyed. Type YES: " ok
[[ $ok == YES ]] || exit 1
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
mount -o fmask=0077,dmask=0077 "$ESP" /mnt/boot
mount "$HOMED" /mnt/home

# 3. Pkg install
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    grep -q '^\[multilib\]' /etc/pacman.conf || { echo "Failed to enable multilib"; exit 1; }
fi

pacstrap -K -P /mnt $PKGS_CORE

genfstab -U /mnt >> /mnt/etc/fstab

# 4. Basic setup
sed -i "s/^#$LOCALE/$LOCALE/" /mnt/etc/locale.gen
echo "LANG=$LOCALE" > /mnt/etc/locale.conf
echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf

echo "$HOST_NAME" > /mnt/etc/hostname
cat "$FD/hosts" | sed "s/\$HOST_NAME/$HOST_NAME/g" >> /mnt/etc/hosts

mkdir -p /mnt/etc/systemd/network
cp "$FD/20-wired.network" /mnt/etc/systemd/network/20-wired.network
install -Dm644 "$FD/main.conf" /mnt/etc/iwd/main.conf

echo '%wheel ALL=(ALL:ALL) ALL' > /mnt/etc/sudoers.d/10-wheel && chmod 440 /mnt/etc/sudoers.d/10-wheel

arch-chroot /mnt /bin/bash -euo pipefail <<CHR1_EOF
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
locale-gen
useradd -m -G wheel "$USERNAME"
visudo -c
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable iwd
CHR1_EOF

printf 'root:%s\n' "$RPW" | arch-chroot /mnt chpasswd
printf '%s:%s\n' "$USERNAME" "$UPW" | arch-chroot /mnt chpasswd

# 5. Install bootloader
UUID=$(blkid -s PARTUUID -o value "$ROOT")
sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /mnt/etc/mkinitcpio.conf
sed -i 's/ kms / /' /mnt/etc/mkinitcpio.conf

arch-chroot /mnt /bin/bash -euo pipefail <<CHR2_EOF
mkinitcpio -P
bootctl install
CHR2_EOF

cp "$FD/loader.conf" /mnt/boot/loader/loader.conf
sed "s/\$UUID/$UUID/" "$FD/arch.conf" > /mnt/boot/loader/entries/arch.conf

# Extra. Repo and dns link
ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf

git clone "$REPO_URL" "/mnt/home/$USERNAME/repo"
arch-chroot /mnt chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/repo"

# Finishing up
umount -R /mnt

echo "You can now reboot :)"
