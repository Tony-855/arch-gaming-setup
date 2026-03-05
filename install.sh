#!/usr/bin/env bash

set -euo pipefail

################
# Sistema Base #
################

# Colores de interfaz
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

log_ok() { echo -e "${GREEN}[ OK ]${ENDCOLOR} $1"; }
log_error() { echo -e "${RED}[ ERROR ]${ENDCOLOR} $1"; }
log_info() { echo -e "${YELLOW}[ INFO ]${ENDCOLOR} $1"; }

# Usuario root
if [ "$(id -u)" -eq 0 ]; then
        log_error "No ejecutes este comando como ROOT"
        exit 1
fi

# Comprobar wifi
check_internet() {
         ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1
}
if check_internet; then
     log_ok "Conexión Wi-Fi en orden."
else
     log_error "Compruebe su conexión Wi-Fi."
        exit 1
fi
# Activar sudo al inicio
sudo -v
# Instalación de paru
install_paru() {
        log_info "Clonando repositorio de Paru..."

        git clone https://aur.archlinux.org/paru.git
        cd paru || exit
        makepkg -si --noconfirm
        cd .. && rm -rf paru
}
# Comprobación de multilib
enable_multilib() {

    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        log_ok "Multilib ya está habilitado"

    elif grep -q "^#\[multilib\]" /etc/pacman.conf; then
        sudo sed -i '/#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
        log_info "Multilib descomentado y habilitado"

    else
        sudo tee -a /etc/pacman.conf > /dev/null <<EOT
[multilib]
Include = /etc/pacman.d/mirrorlist
EOT
        log_info "Multilib agregado a pacman.conf"
    fi
}
enable_multilib
# Comprobar e instalar Chaotic AUR
check_chaotic() {
       grep -q "^\[chaotic-aur\]" /etc/pacman.conf
}
install_chaotic() {
        if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
                log_info "instalando Chaotic-AUR"
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        sudo pacman-key --lsign-key 3056513887B78AEB
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
        sudo tee -a /etc/pacman.conf > /dev/null <<EOT
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOT
        log_info "Chaotic AUR agregado"
fi
}

# Comprobar dependencias Paru
 if check_chaotic; then
         log_ok "Todo bien"
 else
         log_info "Instalando Chaotic"
         install_chaotic
         sudo pacman -Syy --noconfirm
         if check_chaotic; then
                 log_ok "Chaotic instalado correctamente"
         else
                 log_error "Fallo crítico de Chaotic AUR"
                 exit 1
         fi
 fi
 
# Actualizar sistema
sudo pacman -Syu --noconfirm --needed

# Instalar paquetes base de Arch
sudo pacman -S --needed --noconfirm \
        git base-devel curl wget nano vim unzip 

# Comprobar Paru
check_paru() {
        command -v paru &> /dev/null
}
if check_paru; then
        log_ok "Paru ya está instalado."
else
        log_info "Instalando Paru..."
        install_paru
        sudo pacman -Syu --noconfirm

        if check_paru; then
                log_ok "Paru instalado correctamente."
        else
                log_error "Fallo crítico al instalar Paru."
                exit 1
        fi
fi

###########
# Drivers #
###########

# Solo KERNEL ZEN nvidia 580xx DKMS y GRUB
install_firmware() {

    log_info "Instalando firmware..."

    sudo pacman -S --needed --noconfirm \
        linux-firmware \
        linux-firmware-nvidia \
        intel-ucode

    log_ok "Firmware instalado"
}

check_gpu_dependencies() {
        sudo pacman -S --needed --noconfirm dkms linux-zen-headers 
}

install_gpu_drivers() {
        sudo pacman -S --needed --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools \
        egl-wayland egl-gbm egl-x11 libglvnd
        paru -S --needed --noconfirm nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils \
        nvidia-580xx-settings \
        opencl-nvidia-580xx lib32-opencl-nvidia-580xx libxnvctrl-580xx
}

configure_nvidia() {

    log_info "Configurando módulos NVIDIA..."

    sudo tee /etc/modules-load.d/nvidia.conf > /dev/null <<EOT
nvidia
nvidia_modeset
nvidia_uvm
nvidia_drm
EOT

    log_info "Regenerando initramfs..."

    sudo mkinitcpio -P

    log_info "Activando servicio NVIDIA..."

    sudo systemctl enable nvidia-persistenced.service

    log_ok "Configuración NVIDIA completada"
}
