#!/usr/bin/env bash
set -Eeuo pipefail

############################################
# Arch Gaming Setup Script (Modular)
############################################

exec > >(tee -i install.log) 2>&1

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

log_ok(){ echo -e "${GREEN}[OK]${ENDCOLOR} $1"; }
log_info(){ echo -e "${YELLOW}[INFO]${ENDCOLOR} $1"; }
log_error(){ echo -e "${RED}[ERROR]${ENDCOLOR} $1"; }

TMP_ROOT=""

cleanup(){
  kill "${SUDO_PID:-}" 2>/dev/null || true

  if [[ -n "${TMP_ROOT}" && -d "${TMP_ROOT}" ]]; then
    rm -rf "${TMP_ROOT}"
  fi
}

trap cleanup EXIT INT TERM

############################################
# Safety checks
############################################

require_not_root(){
  if [[ $(id -u) -eq 0 ]]; then
    log_error "Do not run as root"
    exit 1
  fi
}

require_commands(){
  local needed=(curl sudo pacman git lspci)
  local missing=()

  for cmd in "${needed[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    log_error "Missing required commands: ${missing[*]}"
    exit 1
  fi
}


check_internet(){
  curl -s --max-time 5 https://archlinux.org >/dev/null
}

confirm_action(){
  local question="$1"
  local answer

  read -rp "$question [y/N]: " answer

  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    log_info "Operation cancelled"
    exit 0
  fi
}

require_not_root
require_commands



if check_internet; then
  log_ok "Internet connection detected"
else
  log_error "No internet connection"
  exit 1
fi

confirm_action "This script modifies system files and installs many packages. Continue?"

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
# Bootloader detection
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
# System prep
############################################

enable_multilib(){
  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    log_info "Enabling multilib repository"
    sudo sed -i '/#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
     fi
}

optimize_pacman(){
  log_info "Applying safe pacman tweaks"
#!/usr/bin/env bash
set -euo pipefail
set -Eeuo pipefail
}

############################################
# Arch Gaming Setup Script (Modular)
############################################

exec > >(tee -i install.log) 2>&1

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

log_ok(){ echo -e "${GREEN}[OK]${ENDCOLOR} $1"; }
log_info(){ echo -e "${YELLOW}[INFO]${ENDCOLOR} $1"; }
log_error(){ echo -e "${RED}[ERROR]${ENDCOLOR} $1"; }

TMP_ROOT=""

cleanup(){
  kill "${SUDO_PID:-}" 2>/dev/null || true

  if [[ -n "${TMP_ROOT}" && -d "${TMP_ROOT}" ]]; then
    rm -rf "${TMP_ROOT}"
  fi
}

trap cleanup EXIT INT TERM

############################################
# Safety checks
############################################

if [[ $(id -u) -eq 0 ]]; then
  log_error "Do not run as root"
  exit 1
fi
require_not_root(){
  if [[ $(id -u) -eq 0 ]]; then
    log_error "Do not run as root"
    exit 1
  fi
}

require_commands(){
  local needed=(curl sudo pacman git lspci)
  local missing=()

  for cmd in "${needed[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    log_error "Missing required commands: ${missing[*]}"
    exit 1
  fi
}

check_internet(){
  curl -s --max-time 5 https://archlinux.org >/dev/null
}

confirm_action(){
  local question="$1"
  local answer

  read -rp "$question [y/N]: " answer

  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    log_info "Operation cancelled"
    exit 0
  fi
}

require_not_root
require_commands

if check_internet; then
  log_ok "Internet connection detected"
else
  log_error "No internet connection"
  exit 1
fi

confirm_action "This script modifies system files and installs many packages. Continue?"

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
# Bootloader detection
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
# System prep
############################################

enable_multilib(){

  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then

    log_info "Enabling multilib repository"

    sudo sed -i '/#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
  fi
}

optimize_pacman(){
  log_info "Applying safe pacman tweaks"
  
  sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
  sudo sed -i 's/^#ParallelDownloads =.*/ParallelDownloads = 8/' /etc/pacman.conf

  if ! grep -q "^ILoveCandy" /etc/pacman.conf; then
    sudo sed -i '/^ParallelDownloads/a ILoveCandy' /etc/pacman.conf
  fi
}

refresh_databases(){
  log_info "Refreshing package databases"
  sudo pacman -Syy --noconfirm
}

update_system(){
  log_info "Updating system packages"
  sudo pacman -Syu --noconfirm
}

############################################
# Base packages
############################################

install_base(){
  sudo pacman -S --needed --noconfirm \
    git base-devel curl wget nano vim unzip reflector
}

############################################
# Optional Chaotic-AUR repo
############################################

setup_chaotic_aur(){
  local answer

  if grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    log_ok "Chaotic-AUR is already configured"
    return
  fi

  read -rp "Do you want to configure Chaotic-AUR repository? [y/N]: " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    log_info "Skipping Chaotic-AUR setup"
    return
  fi

  log_info "Configuring Chaotic-AUR"

  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  sudo pacman-key --lsign-key 3056513887B78AEB
  sudo pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

  sudo tee -a /etc/pacman.conf >/dev/null <<'CHAOTIC'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
CHAOTIC

  refresh_databases
}


############################################
# Paru installation
############################################

install_paru(){
  if command -v paru &>/dev/null; then
    log_ok "paru already installed"
    return
  fi

  log_info "Installing paru AUR helper"
  
  TMP_ROOT=$(mktemp -d)
  pushd "$TMP_ROOT" >/dev/null

  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm
 
  popd >/dev/null

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
    *)
      log_info "Unknown CPU vendor; skipping microcode"
      ;;
  esac
}

############################################
# NVIDIA Drivers (Gaming optimized)
############################################

install_nvidia(){
   log_info "Installing NVIDIA drivers and gaming dependencies"

  sudo pacman -S --needed --noconfirm \
    dkms \
    linux-zen \
    linux-zen-headers \
    libglvnd \
    vulkan-icd-loader \
    lib32-vulkan-icd-loader \
    vulkan-tools \
    egl-wayland \
    egl-gbm \
    egl-x11 \
    lib32-libglvnd

  paru -S --needed --noconfirm \
    nvidia-580xx-dkms \
    nvidia-580xx-utils \
    lib32-nvidia-580xx-utils \
    nvidia-580xx-settings \
    opencl-nvidia-580xx \
    lib32-opencl-nvidia-580xx \
    libxnvctrl-580xx

}

configure_nvidia(){
 log_info "Configuring NVIDIA modules"
 sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<EOF2
options nvidia_drm modeset=1

EOF2
  sudo mkinitcpio -P
  sudo systemctl enable nvidia-persistenced.service

  if [[ "$BOOTLOADER" == "grub" ]]; then
    if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
      sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 /' /etc/default/grub
    fi
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  elif [[ "$BOOTLOADER" == "systemd-boot" ]]; then
    shopt -s nullglob
     for entry in /boot/loader/entries/*.conf; do
      if [[ -f "$entry" ]] && ! grep -q "nvidia_drm.modeset=1" "$entry"; then
        sudo sed -i '/^options / s/$/ nvidia_drm.modeset=1/' "$entry"
      fi
    done

    shopt -u nullglob
  else
    log_info "Bootloader not recognized. Add nvidia_drm.modeset=1 manually if needed"
  fi
}

############################################
# KDE Plasma Minimal
############################################

install_plasma(){
  echo "Instalando entorno KDE Plasma y componentes de interfaz..."
  sudo pacman -S --needed --noconfirm \
    plasma-desktop \
    plasma-welcome \
    systemsettings \
    plasma-pa \
    plasma-nm \
    powerdevil \
    power-profiles-daemon \
    kscreen \
    kde-gtk-config \
    breeze-gtk \
    xdg-desktop-portal-kde \
    konsole \
    dolphin \
    kate \
    sddm-kcm \
    kio-admin \
    bluedevil \
    ark \
    networkmanager \
    kwalletmanager \
    kvantum-qt5 \
    kitty

  sudo systemctl enable sddm
  sudo systemctl enable NetworkManager
  sudo systemctl enable power-profiles-daemon
}



install_audio_bluetooth(){
  log_info "Installing PipeWire and Bluetooth stack"
  sudo pacman -S --needed --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    bluez \
    bluez-utils \
    pavucontrol

  sudo systemctl enable bluetooth
}

############################################
# Gaming stack
############################################

install_gaming(){
  log_info "Instalando entorno Gaming y utilidades de sistema"

  sudo pacman -S --needed --noconfirm \
    steam \
    lutris \
    wine-staging \
    winetricks \
    wine-mono \
    wine-gecko \
    gamescope \
    mangohud \
    lib32-mangohud \
    firefox 
    
  sudo pacman -S --needed --noconfirm \
    btop fastfetch fish neovim tree ncdu duf irqbalance cava

  paru -S --needed --noconfirm \
    proton-ge-custom-bin \
    ananicy-cpp \
    vkbasalt lib32-vkbasalt \
    vesktop heroic-games-launcher-bin \
    preload \
    xone-dkms-git dxvk-bin vkd3d-proton-bin

  sudo systemctl enable --now irqbalance
  sudo systemctl enable --now preload
  sudo systemctl enable --now ananicy-cpp

}

############################################
# Gaming kernel tweaks
############################################

configure_gaming_kernel(){
  log_info "Aplicando optimizaciones de Kernel (Gaming + HDD)"
  
  # Usamos un solo archivo para centralizar las mejoras
  sudo tee /etc/sysctl.d/80-gamecompatibility.conf > /dev/null <<EOF2
vm.max_map_count = 2147483642
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
kernel.sched_autogroup_enabled = 1
EOF2
  
  sudo sysctl --system
}



############################################
# Menu
############################################

menu(){
  clear

  echo "Arch Gaming Setup"
  echo
  echo "1) Drivers (microcode + NVIDIA if detected)"
  echo "2) Desktop (KDE + NetworkManager)"
  echo "3) Gaming (apps + kernel tweaks + services)"
  echo "4) Audio/Bluetooth stack"
  echo "5) Full install"
  echo "6) Prep only (multilib/pacman/update/Chaotic-AUR)"
  echo

  read -rp "Option: " OPTION

  case "$OPTION" in
    1)
      install_microcode

      if [[ "$GPU" == "nvidia" ]]; then
        install_nvidia
        configure_nvidia
      fi
      ;;
    2)
      install_plasma
      ;;
    3)
      install_gaming
      configure_gaming_kernel
      ;;
    4)
      install_audio_bluetooth
      ;;
    5)
      install_microcode

      if [[ "$GPU" == "nvidia" ]]; then
        install_nvidia
        configure_nvidia
      fi

      install_plasma
      install_audio_bluetooth
      install_gaming
      configure_gaming_kernel
      ;;
    6)
      log_ok "Preparation completed"
      ;;
    *)
      log_error "Invalid option"
      exit 1
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
optimize_pacman
refresh_databases
update_system
install_base
setup_chaotic_aur
install_paru

menu

log_ok "Instalación terminada, por favor, reinicie el sistema."
