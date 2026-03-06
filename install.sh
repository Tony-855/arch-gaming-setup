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
         curl -s --max-time 5 https://archlinux.org >/dev/null || return 1
}
if check_internet; then
     log_ok "Conexión Wi-Fi en orden."
else
     log_error "Compruebe su conexión Wi-Fi."
        exit 1
fi

# Activar sudo al inicio
keep_sudo_alive() {
    while true; do
    sudo -n true
    sleep 60
done &
SUDO_PID=$!
}

sudo -v
keep_sudo_alive
# Instalación de paru
install_paru() {
        log_info "Clonando repositorio de Paru..."
        rm -rf paru
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
        sudo pacman -Syu --noconfirm
    fi
}
enable_multilib
# Comprobar e instalar Chaotic AUR
check_chaotic() {
       grep -q "^\[chaotic-aur\]" /etc/pacman.conf || return 1
}
install_chaotic() {
       if ! check_chaotic; then

        log_info "Instalando Chaotic AUR..."

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
sudo pacman -Syu --noconfirm

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

# Preparando dependencias para Kernel Zen y NVIDIA...
install_firmware() {

    log_info "Instalando firmware..."

    sudo pacman -S --needed --noconfirm \
        linux-firmware \
        intel-ucode

    log_ok "Firmware instalado"
}

check_gpu_dependencies() {

    log_info "Instalando dependencias GPU..."

    sudo pacman -S --needed --noconfirm \
        dkms \
        linux-zen \
        linux-zen-headers \
        libglvnd \
        vulkan-icd-loader \
        lib32-vulkan-icd-loader \
        vulkan-tools
}

# 3. Instalación de Drivers NVIDIA (Capa de compatibilidad)
install_gpu_drivers() {
    log_info "Instalando drivers NVIDIA 580xx y soporte Wayland..."
    
   # Paquetes de soporte para Wayland/X11
    sudo pacman -S --needed --noconfirm \
        egl-wayland \
        egl-gbm \
        egl-x11

    # Instalación del driver específico vía AUR
    paru -S --needed --noconfirm \
        nvidia-580xx-dkms \
        nvidia-580xx-utils \
        lib32-nvidia-580xx-utils \
        nvidia-580xx-settings \
        opencl-nvidia-580xx \
        lib32-opencl-nvidia-580xx \
        libxnvctrl-580xx
}

configure_nvidia() {

    log_info "Configurando módulos NVIDIA..."
    sudo sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<EOT
options nvidia_drm modeset=1
EOT
    log_info "Regenerando Initramfs..."
    sudo mkinitcpio -P
    
    log_info "Activando servicio NVIDIA..."

    sudo systemctl enable nvidia-persistenced.service

    log_ok "Configuración NVIDIA completada."
}
configure_grub() {

    log_info "Configurando parámetros del kernel para NVIDIA..."

    sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 /' /etc/default/grub

    log_info "Regenerando configuración de GRUB..."

    sudo grub-mkconfig -o /boot/grub/grub.cfg

    log_ok "GRUB configurado para NVIDIA + Wayland"
}
configure_gaming () {
    log_info "Configurando..."
    sudo tee /etc/sysctl.d/80-gamecompatibility.conf > /dev/null <<EOT
vm.max_map_count = 2147483642
EOT
    log_info "Reiniciando servivios"
    sudo sysctl --system
}

###################
# Entorno gráfico #
###################

install_graphics() {
    log_info "Instalando base mínima de Plasma..."

    sudo pacman -S --needed --noconfirm \
        xorg-server \
        plasma-desktop \
        sddm \
        konsole \
        dolphin \
        kate \
        ark \
        plasma-nm \
        power-profiles-daemon \
        systemsettings \
        khotkeys \
        sddm-kcm \
        networkmanager

    log_ok "Entorno ligero instalado."
}
enable_display_manager() {
    # Habilitar servicios esenciales
    
    log_info "Activando SDDM y NetworkManager..."

    sudo systemctl enable sddm.service
    sudo systemctl enable NetworkManager

    log_ok "Servicios activados."
}

###########################
# Herramientas esenciales #
###########################

install_gaming_setup() {
    log_info "Instalando ecosistema Gaming y herramientas..."

    # 1. PLATAFORMAS Y CAPAS DE COMPATIBILIDAD
    # Nota: No instalamos DXVK/VKD3D aquí porque Steam/Lutris ya los gestionan internamente
    local GAMING_CORE=(
        steam
        lutris
        wine-staging
        wine-gecko
        wine-mono
        winetricks
        gamescope        # Micro-compositor para mejorar rendimiento en juegos
    )

    # 2. COMUNICACIÓN E INTERNET
    local NET_TOOLS=(
        firefox
        vesktop          # Discord optimizado (mejor que el original para compartir pantalla)
        yt-dlp           # Descarga de contenido
    )

    # 3. LIBRERÍAS DE COMPATIBILIDAD (32 y 64 bits).
    local COMPAT_LIBS=(
        giflib lib32-giflib
        libpng lib32-libpng
        libldap lib32-libldap
        gnutls lib32-gnutls
        mpg123 lib32-mpg123
        openal lib32-openal
        v4l-utils lib32-v4l-utils
        libgpg-error lib32-libgpg-error
        alsa-plugins lib32-alsa-plugins
        alsa-lib lib32-alsa-lib
        libjpeg-turbo lib32-libjpeg-turbo
        sqlite lib32-sqlite
        libxcomposite lib32-libxcomposite
        libxinerama lib32-libxinerama
        ncurses lib32-ncurses
        opencl-icd-loader lib32-opencl-icd-loader
        libxslt lib32-libxslt
        gst-plugins-base-libs lib32-gst-plugins-base-libs
    )

    # 4. AUDIO, RENDIMIENTO Y MONITOREO
    local PERF_AUDIO=(
        pipewire-alsa
        pipewire-pulse
        lib32-libpulse
        pavucontrol
        easyeffects      # Filtros de audio y reducción de ruido
        alsa-utils
        ananicy-cpp
        mangohud         # Monitor de FPS y recursos
        lib32-mangohud
        goverlay         # Interfaz gráfica para configurar MangoHud/vkBasalt
        irqbalance       # Optimiza el uso de núcleos del i3
        preload          # Acelera la apertura de apps frecuentes
    )

    log_info "Instalando paquetes desde repositorios oficiales..."
    sudo pacman -S --needed --noconfirm \
        "${GAMING_CORE[@]}" \
        "${NET_TOOLS[@]}" \
        "${COMPAT_LIBS[@]}" \
        "${PERF_AUDIO[@]}"

    # 5. PAQUETES AUR (Instalación con Paru)
    log_info "Instalando herramientas adicionales desde AUR..."
    paru -S --needed --noconfirm \
        vkbasalt lib32-vkbasalt ananicy-rules-git \
        proton-ge-custom-bin \
        xone-dkms-git    # Driver para mandos de Xbox (si usas uno)

    # Activar servicios de rendimiento
    sudo systemctl enable --now irqbalance
    sudo systemctl enable --now preload
    sudo systemctl enable --now ananicy-cpp.service

    log_ok "Instalación Gaming finalizada con éxito."
}
install_firmware
check_gpu_dependencies
install_gpu_drivers
configure_nvidia
configure_grub
configure_gaming
install_graphics
enable_display_manager
install_gaming_setup

kill "${SUDO_PID:-}" 2>/dev/null || true

log_ok "Instalación completada correctamente"
log_info "Reinicia el sistema para aplicar los cambios"
