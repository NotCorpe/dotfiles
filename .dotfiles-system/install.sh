#!/bin/bash
# ============================================================
# Dotfiles install script — Sam's Arch Linux ThinkPad
# Usage: bash install.sh
# ============================================================
set -e

DOTFILES_REPO="https://github.com/TON_USER/dotfiles"  # <-- à changer
SYSTEM_REPO="https://github.com/TON_USER/dotfiles-system"  # <-- à changer

echo "==> [1/5] Installation des packages..."
PACKAGES=(
  # Base système
  base base-devel linux linux-firmware linux-headers amd-ucode
  btrfs-progs lvm2 efibootmgr sudo
  # Réseau
  iwd openssh wireless_tools
  # Wayland / Desktop
  niri sddm greetd xorg-xwayland xwayland-satellite seatd
  pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber
  gst-plugin-pipewire libpulse
  xdg-desktop-portal-gnome xdg-utils
  # Apps
  ghostty alacritty firefox neovim vim nano
  fuzzel mako swaybg swayidle swaylock wdisplays
  telegram-desktop vlc obsidian
  # Fonts
  ttf-jetbrains-mono-nerd
  # Outils
  git ripgrep glow htop smartmontools reflector wget unzip
  usbutils wl-clipboard npm uv
  # Bluetooth
  bluez bluez-utils
  # Virt
  qemu-desktop libvirt virt-manager edk2-ovmf podman-docker dnsmasq
  # Power
  power-profiles-daemon zram-generator
  # Drivers AMD
  vulkan-radeon xf86-video-amdgpu xf86-video-ati
  vulkan-intel intel-media-driver libva-intel-driver
  # Monitoring
  flatpak snapper
)
sudo pacman -S --needed "${PACKAGES[@]}"

echo "==> [2/5] Installation des packages AUR..."
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
  (cd /tmp/yay-bin && makepkg -si --noconfirm)
fi
yay -S --needed \
  antigravity quickshell-git dms-shell-bin greetd-dms-greeter-git \
  arduino-ide-bin appimagelauncher matugen zeroclaw dgop yay-bin-debug

echo "==> [3/5] Déploiement des dotfiles..."
git clone --bare "$DOTFILES_REPO" "$HOME/.dotfiles"
alias dots='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dots config --local status.showUntrackedFiles no
dots checkout || {
  echo "Conflits détectés — backup des fichiers existants dans ~/.config-backup"
  mkdir -p ~/.config-backup
  dots checkout 2>&1 | grep "^\s" | awk '{print $1}' | xargs -I{} mv {} ~/.config-backup/{}
  dots checkout
}

echo "==> [4/5] Application des configs système..."
sudo cp sysctl/99-zram.conf /etc/sysctl.d/
sudo sysctl -p /etc/sysctl.d/99-zram.conf
sudo cp udev/60-scheduler.rules /etc/udev/rules.d/
sudo udevadm trigger
sudo systemctl enable --now fstrim.timer
sudo systemctl enable --now power-profiles-daemon
sudo systemctl enable --now bluetooth

echo "==> [5/5] Bootloader (vérifie l'UUID avant d'appliquer !)"
echo "    Fichier : bootloader/arch-entry.conf"
echo "    Commande : sudo cp bootloader/arch-entry.conf /boot/loader/entries/"
echo "    IMPORTANT : vérifie que l'UUID LUKS correspond à ton disque avec : blkid"

echo ""
echo "==> Terminé ! Redémarre et configure GitHub SSH si besoin."
echo "    Alias 'dots' disponible après : source ~/.bashrc"
