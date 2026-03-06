#!/usr/bin/env bash
set -euo pipefail

############################################
# Arch Gaming Setup Script (Modular)
# Inspired by Garuda/CachyOS style setups
############################################

# Logging
exec > >(tee -i install.log) 2>&1

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

log_ok(){ echo -e "${GREEN}[OK]${ENDCOLOR} $1"; }
log_info(){ echo -e "${YELLOW}[INFO]${ENDCOLOR} $1"; }
log_error(){ echo -e "${RED}[ERROR]${ENDCOLOR} $1"; }

############################################
# Safety checks
############################################

if [[ $(id -u) -eq 0 ]]; then
  log_error "Do not run as root"
  exit 1
fi

check_internet(){
  curl -s --max-time 5 https://archlinux.org >/dev/null
}

if check_internet; then
  log_ok "Internet connection detected"
else
  log_error "No internet connection"
  exit 1
fi

sudo -v

############################################
# Keep sudo alive
############################################

keep_sudo_alive(){
  while true; do
    sudo -n true
    sleep 60
  done &
  SUDO_PID=$!
}

keep_sudo_alive

############################################
# System detection
############################################

detect_cpu(){
  if grep -qi intel /proc/cpuinfo; then
    CPU="intel"
  elif grep -qi amd /proc/cpuinfo; then
    CPU="amd"
  else
    CPU="unknown"
  fi

  log_info "CPU detected: $CPU"
}

detect_gpu(){
  if lspci | grep -E "NVIDIA" >/dev/null; then
    GPU="nvidia"
  elif lspci | grep -E "AMD|ATI" >/dev/null; then
    GPU="amd"
  elif lspci | grep -E "Intel" >/dev/null; then
    GPU="intel"
  else
    GPU="unknown"
  fi

  log_info "GPU detected: $GPU"
}

############################################
# Bootloader check
############################################

check_bootloader(){
  if command -v grub-mkconfig &>/dev/null; then
    BOOTLOADER="grub"
  elif command -v bootctl &>/dev/null; then
    BOOTLOADER="systemd-boot"
  else
    BOOTLOADER="unknown"
  fi

  log_info "Bootloader detected: $BOOTLOADER"
}

############################################
# Enable multilib
############################################

enable_multilib(){
  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then

    sudo sed -i '/#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf

    log_info "Enabling multilib"

    sudo pacman -Syy
  fi
}

############################################
# Base packages
############################################

install_base(){

sudo pacman -S --needed --noconfirm \
 git base-devel curl wget nano vim unzip

}

############################################
# Paru installation
############################################

install_paru(){

if ! command -v paru &>/dev/null; then

  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm
  cd ..
  rm -rf paru

fi

}

############################################
# CPU microcode
############################################

install_microcode(){

case "$CPU" in

intel)
 sudo pacman -S --needed --noconfirm intel-ucode
 ;;

amd)
 sudo pacman -S --needed --noconfirm amd-ucode
 ;;

esac

}

############################################
# GPU Drivers
############################################

install_nvidia(){

sudo pacman -S --needed --noconfirm \
 dkms linux-zen linux-zen-headers \
 vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools \
 egl-wayland egl-gbm egl-x11

paru -S --needed --noconfirm \
 nvidia-580xx-dkms \
 nvidia-580xx-utils \
 lib32-nvidia-580xx-utils

}

configure_nvidia(){

sudo sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<EOF
options nvidia_drm modeset=1
EOF

sudo mkinitcpio -P

sudo systemctl enable nvidia-persistenced.service

if [[ "$BOOTLOADER" == "grub" ]]; then

 sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 /' /etc/default/grub
 sudo grub-mkconfig -o /boot/grub/grub.cfg

fi

}

############################################
# Desktop Environment
############################################

install_plasma(){

sudo pacman -S --needed --noconfirm \
 xorg-server \
 plasma-desktop \
 sddm \
 konsole dolphin kate ark \
 plasma-nm systemsettings \
 networkmanager \
 power-profiles-daemon

sudo systemctl enable sddm
sudo systemctl enable NetworkManager

}

############################################
# Gaming Stack
############################################

install_gaming(){

sudo pacman -S --needed --noconfirm \
 steam lutris \
 wine-staging winetricks wine-mono wine-gecko \
 gamescope mangohud lib32-mangohud \
 pipewire-alsa pipewire-pulse \
 pavucontrol

sudo pacman -S --needed --noconfirm \
 firefox vesktop

sudo pacman -S --needed --noconfirm \
 btop fastfetch fish neovim tree ncdu duf

sudo pacman -S --needed --noconfirm \
 irqbalance preload

paru -S --needed --noconfirm \
 proton-ge-custom-bin \
 vkbasalt lib32-vkbasalt \
 ananicy-cpp ananicy-rules-git

sudo systemctl enable --now irqbalance
sudo systemctl enable --now preload
sudo systemctl enable --now ananicy-cpp

}

############################################
# System Tweaks
############################################

configure_gaming_kernel(){

sudo tee /etc/sysctl.d/80-gamecompatibility.conf > /dev/null <<EOF
vm.max_map_count = 2147483642
EOF

sudo sysctl --system

}

############################################
# Main installer menu
############################################

menu(){

clear

echo "Arch Gaming Setup"

echo "1) Drivers"
echo "2) Desktop"
echo "3) Gaming"
echo "4) Full install"

read -rp "Option: " OPTION

case $OPTION in

1)
 install_microcode
 install_nvidia
 configure_nvidia
 ;;

2)
 install_plasma
 ;;

3)
 install_gaming
 configure_gaming_kernel
 ;;

4)
 install_microcode
 install_nvidia
 configure_nvidia
 install_plasma
 install_gaming
 configure_gaming_kernel
 ;;

*)
 log_error "Invalid option"
 ;;

esac

}

############################################
# Execution
############################################


detect_cpu

detect_gpu

check_bootloader

enable_multilib

install_base

install_paru

menu

kill "${SUDO_PID:-}" 2>/dev/null || true

log_ok "Installation finished"
log_info "Reboot recommended"
