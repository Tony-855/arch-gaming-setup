#!/bin/bash

# Arch Linux Gaming Script v1.0.
# Mi primer script de Arch Linux para uso diario y juegos basado en CachyOS y Garuda.

LOG_FILE="script.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Colores para mejor lectura y estética.
ROJO='\033[1;31m'        # ${ROJO}
AMARILLO='\033[1;33m'    # ${AMARILLO}
VERDE='\033[1;32m'       # ${VERDE}

# ROOT
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${ROJO}NO corras este script como root o sudo."
    echo -e "${VERDE}Por favor, corre este script como un usuario normal: ./archie.sh"
    exit 1
fi

# Comprobar el acceso al internet. 
comprobar_internet() {
	echo -e "${AMARILLO}Comprobando internet..."
	if ping -c 1 8.8.8.8 &> /dev/null; then
		echo -e "${VERDE}El internet funciona."
	else
		echo -e "${ROJO}Comprueba tu conexión Wi-Fi."
		exit 1
	fi
}
#              #
# REPOSITORIOS #
#              #

# Comprobar y/o activar Multilib.
activar_multilib() {
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo -e "${AMARILLO}Activando multilib..."
        sudo sed -i '/#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    else
        echo -e "${VERDE}Repositorio Multilib ya estaba activado."
    fi
}
# Agregar repositorios ChaotirAUR (Preferiblemente para Paru).
chaotic_aur() {
	#Activar el ChaoticAUR en pacman.conf
	if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
		echo -e "${AMARILLO}Activando repositorios ChaoticAUR..."

		sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
                sudo pacman-key --lsign-key 3056513887B78AEB 
		sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
                sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

		sudo tee -a /etc/pacman.conf > /dev/null <<EOT
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOT
		echo -e "${VERDE}ChaoticAUR fue agregado."
	else
		echo "${VERDE}ChaoticAUR ya estaba agregado."
	fi
}
# Paru y sistema base
update_system() {
    echo -e "${VERDE}Actualizando sistema..."
    sudo pacman -Syu --noconfirm
    # Paru
    sudo pacman -S --needed --noconfirm paru
}
# Entorno de escritorio
install_kde() {
	echo -e "${AMARILLO}Instalando KDE..."
	sudo pacman -S --needed --noconfirm xorg sddm
        sudo systemctl enable sddm
	sudo pacman -S --needed --noconfirm ark dolphin kate konsole plasma-meta plasma-workspace
	sudo systemctl enable NetworkManager
}
command -v paru &>/dev/null || {
    echo -e "${ROJO}paru no está instalado."
    exit 1
}
# Drivers de gráfica
install_nvidia() {
	echo -e "${VERDE}Iniciando la descarga de Drivers Nvidia 580xx, esto puede tomar un tiempo."
	# Kernel (IMPORTANTE tener ZEN instalado antes).
	sudo pacman -S --needed --noconfirm linux-zen-headers base-devel
	# Nvidia 
	paru -S --needed --noconfirm nvidia-580xx-dkms nvidia-580xx-utils nvidia-settings-580xx \
		lib32-nvidia-utils-580xx lib32-opencl-nvidia-580xx opencl-nvidia-580xx \
		lact nvtop
        # mkinitcpio seguro
        if ! grep -q "nvidia" /etc/mkinitcpio.conf; then
                echo -e "${AMARILLO}Agregando módulos NVIDIA a mkinitcpio..."
                sudo sed -i '/^MODULES=/ s/)/ nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
        fi 
	# GRUB seguro (no duplicar)
        if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
                sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&nvidia_drm.modeset=1 nvidia_drm.fbdev=1 /' /etc/default/grub
        fi
        # Regenerar
        sudo grub-mkconfig -o /boot/grub/grub.cfg
	sudo mkinitcpio -P
	sudo systemctl enable --now nvidia-persistenced # Servicio de Nvidia

	# Completado
	echo -e "${VERDE}Instalación de drivers Nvidia terminado, necesario reiniciar para aplicar cambios."
}
# Instalación gaming
paquetes_gaming() {
	echo -e "${AMARILLO}Descarga de programas y juegos esenciales..."
	# Dependencias necesarias para Nvidia
	sudo pacman -S --needed --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools \
		mesa lib32-mesa mesa-utils
	# Programas
	sudo pacman -S --needed --noconfirm steam lutris wine-staging wine-mono bottles winetricks gamescope mangohud lib32-mangohud goverlay \
		ananicy-cpp irqbalance \
                bluez bluez-utils
	# Servicios
	sudo systemctl enable --now ananicy-cpp
	sudo systemctl enable --now irqbalance
	sudo systemctl enable --now bluetooth
	# Programas AUR
	paru -S --needed --noconfirm vkbasalt lib32-vkbasalt protonplus xone-dkms-git heroic-games-launcher-bin ananicy-rules-git xwaylandvideobridge
}
compatibilidad() {
	if ! grep -q "vm.max_map_count = 2147483642" /etc/sysctl.d/80-gamecompatibility.conf > /dev/null; then
		echo -e "${AMARILLO}Agregando compatibilidad gamer..."
		sudo tee -a "/etc/sysctl.d/80-gamecompatibility.conf" <<EOT
vm.max_map_count = 2147483642
EOT
                echo -e "${VERDE}Agregado correctamente."
		sudo sysctl --system
	else
		echo -e "${VERDE}Ya estaba activado."
	fi
}
# SUDO
sudo -v
main() {
    comprobar_internet

    activar_multilib
    chaotic_aur
    update_system

    install_kde
    install_nvidia
    paquetes_gaming
    compatibilidad

    echo -e "${VERDE}Instalación completada. Reinicia el sistema.${NC}"
}

main
