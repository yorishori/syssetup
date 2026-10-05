#! /bin/bash
set -euo pipefail

# Run as user, not root/sudo
if [[ $EUID -eq 0 ]]; then
    echo "Don't run as root or with sudo"
    exit 1
fi
if ! ping -c 1 -W 3 google.com >/dev/null 2>&1; then
    echo "No internet. Plugin ethernet or use iwctl to connect to a network"
    exit 1
fi

DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
PKGFILE="$DIR/.pkgs"
CONFIGDIR="$DIR/config"

source "$PKGFILE"

# .netrc (calendar login); empty machine skips
if [[ ! -f $HOME/.netrc ]]; then
    read -rp "netrc machine (empty to skip): " NRC_HOST
    if [[ -n $NRC_HOST ]]; then
        read -rp "netrc login: " NRC_USER
        read -rp "netrc password: " NRC_PW
        (umask 077; printf 'machine %s login %s password %s\n' "$NRC_HOST" "$NRC_USER" "$NRC_PW" > "$HOME/.netrc")
    fi
fi

# Install desktop, shell and utility packages
sudo pacman -Syu --needed --noconfirm $PKGS_DE $PKGS_SHELL $PKGS_UTILS

# YAY Setup
[[ -d $HOME/repo/yay ]] || git clone https://aur.archlinux.org/yay.git $HOME/repo/yay
(cd $HOME/repo/yay && makepkg -si)

# Install YAY packages
yay -S --needed --noconfirm --removemake $PKGS_AUR

# NYST Setup
[[ -d $HOME/repo/nyst ]] || git clone https://github.com/yorishori/nyst.git $HOME/repo/nyst
(cd $HOME/repo/nyst/arch && makepkg -si)

# Install config files
mkdir -p $HOME/.config/

for d in fontconfig gtk-3.0 gtk-4.0 kitty nvim quickshell sway xdg-desktop-portal xdg-desktop-portal-termfilechooser xdg-desktop-portal-wlr yazi; do
  rsync -a --delete $CONFIGDIR/"$d/" $HOME/.config/"$d/"
done

for d in .bash_profile .bashrc .inputrc; do
  rsync -a --delete $CONFIGDIR/home/"$d" $HOME/"$d"
done

# Yazi plugins (package.toml)
ya pkg install

# Home folders (Documents, Downloads, ...)
xdg-user-dirs-update

# Enable/start units
sudo systemctl enable --now systemd-timesyncd paccache.timer fstrim.timer

# Set-up gtk settings
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
gsettings set org.gnome.desktop.interface cursor-size 24

echo "You may reboot your system ＼(≧▽≦)／"
