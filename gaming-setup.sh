#!/usr/bin/env bash
# ============================================================
#  ARCH AUTO REBUILD SCRIPT — Antony Edition
#  Goal: restore drivers + gaming + NVIDIA + Wayland setup fast
# ============================================================

set -euo pipefail

GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

if [ "$(id -u)" -eq 0 ]; then
  echo "Do NOT run this script as root."
  exit 1
fi

# ------------------------------------------------------------
# 0. BASIC CHECKS
# ------------------------------------------------------------

echo -e "${GREEN}Checking internet...${RESET}"
ping -c 1 archlinux.org >/dev/null || {
  echo "No internet connection."; exit 1;
}

sudo -v

# ------------------------------------------------------------
# 1. SYSTEM UPDATE
# ------------------------------------------------------------

echo -e "${GREEN}Updating system...${RESET}"
sudo pacman -Syu --noconfirm

# ------------------------------------------------------------
# 2. BASE TOOLS
# ------------------------------------------------------------

echo -e "${GREEN}Installing base packages...${RESET}"
sudo pacman -S --needed --noconfirm \
  git base-devel curl wget nano vim unzip \
  mesa mesa-utils vulkan-tools

# ------------------------------------------------------------
# 3. INSTALL PARU (AUR HELPER)
# ------------------------------------------------------------

if ! command -v paru &> /dev/null; then
  echo -e "${GREEN}Installing Paru...${RESET}"
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm
  cd ..
  rm -rf paru
else
  echo "Paru already installed."
fi

# ------------------------------------------------------------
# 4. NVIDIA DRIVER STACK (GTX 750)
# ------------------------------------------------------------

echo -e "${GREEN}Installing NVIDIA 580xx DKMS drivers...${RESET}"

sudo pacman -S --needed --noconfirm \
  dkms linux-zen-headers \
  vulkan-icd-loader lib32-vulkan-icd-loader \
  lib32-mesa nvtop

paru -S --needed --noconfirm \
  nvidia-580xx-dkms \
  nvidia-580xx-utils \
  lib32-nvidia-580xx-utils \
  nvidia-580xx-settings

# Kernel rebuild
sudo mkinitcpio -P

# ------------------------------------------------------------
# 5. NVIDIA WAYLAND FIXES
# ------------------------------------------------------------

echo -e "${GREEN}Applying NVIDIA Wayland environment fixes...${RESET}"

sudo bash -c 'cat > /etc/environment <<EOF
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
LIBVA_DRIVER_NAME=nvidia
EOF'

sudo mkdir -p /etc/modprobe.d
sudo bash -c 'cat > /etc/modprobe.d/nvidia.conf <<EOF
options nvidia NVreg_UsePageAttributeTable=1
options nvidia-drm modeset=1 fbdev=1
EOF'

sudo mkinitcpio -P

# Persistence daemon
sudo systemctl enable nvidia-persistenced.service

# ------------------------------------------------------------
# 6. WAYLAND + NIRI ENVIRONMENT
# ------------------------------------------------------------

echo -e "${GREEN}Installing Niri environment...${RESET}"

sudo pacman -S --needed --noconfirm \
  niri xorg-xwayland xwayland-satellite \
  xdg-desktop-portal-gnome xdg-desktop-portal-gtk \
  alacritty waybar

paru -S --needed --noconfirm \
  matugen cava qt6-multimedia-ffmpeg

# ------------------------------------------------------------
# 7. GAMING STACK
# ------------------------------------------------------------

echo -e "${GREEN}Installing gaming packages...${RESET}"

sudo pacman -S --needed --noconfirm \
  steam lutris wine-staging winetricks \
  gamemode lib32-gamemode \
  mangohud lib32-mangohud goverlay \
  gamescope

paru -S --needed --noconfirm \
  proton-ge-custom-bin \
  vkbasalt lib32-vkbasalt \
  dxvk-bin vkd3d-proton-bin

# ------------------------------------------------------------
# 8. CPU PERFORMANCE TUNING
# ------------------------------------------------------------

echo -e "${GREEN}Configuring CPU performance governor...${RESET}"

sudo pacman -S --needed --noconfirm cpupower
sudo systemctl enable cpupower.service

sudo sed -i "s/#governor=.*/governor='performance'/" /etc/default/cpupower || true

# ------------------------------------------------------------
# 9. QUALITY OF LIFE
# ------------------------------------------------------------

echo "export MANGOHUD=1" >> ~/.profile

# ------------------------------------------------------------
# DONE
# ------------------------------------------------------------

echo -e "${GREEN}=====================================${RESET}"
echo -e "${GREEN} Arch rebuild completed successfully ${RESET}"
echo -e "${GREEN} Reboot recommended! ${RESET}"
echo -e "${GREEN}=====================================${RESET}"
