#!/usr/bin/env bash

set -euo pipefail

# Verificaciones del sistema #
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
        cd ..
        rm -rf paru
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
         if check_chaotic; then
                 log_ok "Chaotic instalado correctamente"
         else
                 log_error "Fallo crítico de Chaotic AUR"
                 exit 1
         fi
 fi
 
# Actualizar sistema
sudo pacman -Syyu --noconfirm

# Instalar paquetes base de Arch
sudo pacman -S --needed --noconfirm \
        git base-devel curl wget nano vim unzip \
        mesa mesa-utils vulkan-tools


# Comprobar Paru
check_paru() {
        command -v paru &> /dev/null
}
if check_paru; then
        log_ok "Paru ya está instalado."
else
        log_info "Instalando Paru..."
        install_paru

        if check_paru; then
                log_ok "Paru instalado correctamente."
        else
                log_error "Fallo crítico al instalar Paru."
                exit 1
        fi
fi

log_ok "Instalación base completada"
