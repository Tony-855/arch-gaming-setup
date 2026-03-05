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

# Instalación de paru
install_paru() {
        log_info "Clonando repositorio de Paru..."

        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm
        cd ..
        rm -rf paru
}

# Activar sudo al inicio
sudo -v
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

log_ok "Todo en ordén"
