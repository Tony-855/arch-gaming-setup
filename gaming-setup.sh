#!/bin/bash
set -euo pipefail

GREEN="\e[32m"
RESET="\e[0m"

echo "==========================="
echo " Gaming Setup  -  Antony "
echo "==========================="

ping -c 1 archlinux.org >/dev/null || {
  echo "No hay conexión a internet."
  exit 1
}

if [ "$(id -u)" -eq 0 ]; then
    echo "No ejecutes como root."
    exit 1
fi

sudo -v || exit

   if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib repository..."
    sudo sed -i '/^\s*#\s*\[multilib\]/,/\[/{s/^#//}' /etc/pacman.conf
    sudo pacman -Syy
    echo "Multilib repository has been enabled."
else
    echo "Multilib repository is already enabled."
fi

echo "Actualizando sistema..."
sudo pacman -Syu --noconfirm

#Descargar Yay en mi PC
echo "¿Descargar Yay? (y/n)"
read -r yay

if [[ "$yay" =~ ^[Yy]$ ]]; then
    echo "Descargando yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin || exit
    makepkg -si --noconfirm
    cd ~ && rm -rf yay-bin
else
    echo "Saltando yay..."
fi

if ! command -v yay &> /dev/null; then
    echo "Yay no está instalado. Paquetes AUR no disponibles."
    exit 1
fi

#Drivers
echo "Elige tu GPU:"
echo "1) Nvidia"
echo "2) AMD"
echo "3) Ninguno"
read -r gpu

case $gpu in
    1)
        echo "Instalando drivers Nvidia..."
        sudo pacman -S --needed --noconfirm linux-headers base-devel dkms vulkan-icd-loader lib32-vulkan-icd-loader lib32-mesa lib32-opencl-nvidia vulkan-tools mesa-utils nvtop
        yay -S nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils nvidia-580xx-settings
        sudo systemctl enable --now nvidia-persistenced.service
        sudo mkinitcpio -P
        ;;
    2)
        echo "Instalando drivers AMD..."
        sudo pacman -S --needed --noconfirm mesa mesa-utils vulkan-radeon lib32-vulkan-radeon
        ;;
    3)
        echo "Ninguno"
        ;;
    *)
        echo "Opción inválida"
        ;;
esac

#Descargar paquetes necesarios
echo "¿Instalar paquetes Gaming y utilidades con pacman y yay? (y/n)"
read -r gaming

if [[ "$gaming" =~ ^[Yy]$ ]]; then
    echo "Instalando paquetes Gaming y utilidades"
    sudo pacman -S --needed --noconfirm steam lutris wine-staging winetricks gamemode lib32-gamemode giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal \
    v4l-utils lib32-v4l-utils libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama \
    lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs \
    discord mangohud lib32-mangohud goverlay gamescope bluez bluez-utils lib32-libpulse pipewire pipewire-pulse pipewire-alsa

    yay -S --needed --noconfirm \
vkbasalt lib32-vkbasalt \
proton-ge-custom-bin \
xone-dkms-git \
dxvk-bin \
vkd3d-proton-bin

else
    echo "Saltando este paso"
fi

#Intaladores gráficos
echo "¿Descargar Octopi o Pamac?"
echo "1) Octopi"
echo "2) Pamac"
echo "3) Arch Puro"
read -r pm_choice

case $pm_choice in
    1)
        echo "Instalar Octopi"
        yay -S --noconfirm octopi octopi-notifier
        ;;
    2)
        echo "Instalar Pamac"
        sudo pacman -S --needed --noconfirm glib2-devel glib2
        yay -S --noconfirm libpamac-full pamac
            sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        ;;
    3)
        echo "Para Discover en Arch Puro"
        sudo pacman -S --needed --noconfirm flatpak
        ;;
    *)
        echo "Opción inválida"
        ;;
esac

echo -e "${GREEN}Instalación finalizada correctamente.${RESET}"
echo "Se recomienda reiniciar."
