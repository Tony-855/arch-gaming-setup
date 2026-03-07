#!/usr/bin/env bash
# ======================================================================
# ARCH ALL-IN-ONE SETUP
# Target GPU: NVIDIA GTX 750 (nvidia-580xx-dkms)
# Purpose: Full Arch gaming + dev environment bootstrap
# Features:
#  - Safe Bash practices
#  - Automatic GPU/CPU detection
#  - Pacman optimization
#  - Mirror optimization
#  - Multilib enable
#  - AUR helper install
#  - NVIDIA legacy driver install (580xx DKMS)
#  - KDE Plasma desktop
#  - Gaming stack
#  - Performance tuning
#  - ZRAM
#  - Kernel/sysctl tweaks
#  - Logging
# ======================================================================

set -Eeuo pipefail

LOGFILE="/var/log/arch-allinone.log"
exec > >(tee -a "$LOGFILE") 2>&1

# ----------------------------------------------------------------------
# Colors
# ----------------------------------------------------------------------

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

info(){ echo -e "${BLUE}[INFO]${RESET} $1"; }
ok(){ echo -e "${GREEN}[OK]${RESET} $1"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $1"; }
fail(){ echo -e "${RED}[ERROR]${RESET} $1"; }

# ----------------------------------------------------------------------
# Root check
# ----------------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    fail "Run with sudo"
    exit 1
fi

REAL_USER=${SUDO_USER:-$(whoami)}
USER_HOME="/home/$REAL_USER"

# ----------------------------------------------------------------------
# Detect hardware
# ----------------------------------------------------------------------

detect_hardware(){

    info "Detecting CPU"

    if grep -q AuthenticAMD /proc/cpuinfo; then
        CPU="amd"
    else
        CPU="intel"
    fi

    ok "CPU detected: $CPU"

    info "Detecting GPU"

    GPU=$(lspci | grep -E "VGA|3D")

    echo "$GPU"

}

# ----------------------------------------------------------------------
# Enable multilib
# ----------------------------------------------------------------------

enable_multilib(){

    info "Enabling multilib"

    if ! grep -q "\[multilib\]" /etc/pacman.conf; then
        sed -i '/#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    fi

}

# ----------------------------------------------------------------------
# Pacman optimization
# ----------------------------------------------------------------------

optimize_pacman(){

    info "Optimizing pacman"

    sed -i 's/^#Color/Color/' /etc/pacman.conf
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf

}

# ----------------------------------------------------------------------
# Mirror optimization
# ----------------------------------------------------------------------

optimize_mirrors(){

    info "Optimizing mirrors"

    pacman -S --needed --noconfirm reflector

    reflector \
        --latest 25 \
        --protocol https \
        --sort rate \
        --save /etc/pacman.d/mirrorlist

}

# ----------------------------------------------------------------------
# System update
# ----------------------------------------------------------------------

update_system(){

    info "Updating system"

    pacman -Syu --noconfirm

}

# ----------------------------------------------------------------------
# Base system packages
# ----------------------------------------------------------------------

install_base(){

    info "Installing base tools"

    pacman -S --needed --noconfirm \
        base-devel \
        git \
        curl \
        wget \
        unzip \
        nano \
        neovim \
        htop \
        btop \
        fastfetch \
        linux-headers \
        dkms

}

# ----------------------------------------------------------------------
# Install paru
# ----------------------------------------------------------------------

install_paru(){

    if command -v paru &>/dev/null; then
        ok "paru already installed"
        return
    fi

    info "Installing paru"

    sudo -u "$REAL_USER" git clone https://aur.archlinux.org/paru.git /tmp/paru

    cd /tmp/paru

    sudo -u "$REAL_USER" makepkg -si --noconfirm

    cd /

    rm -rf /tmp/paru

}

# ----------------------------------------------------------------------
# NVIDIA 580xx driver
# ----------------------------------------------------------------------

install_nvidia(){

    info "Installing NVIDIA 580xx DKMS driver"

    pacman -S --needed --noconfirm \
        nvidia-580xx-dkms \
        nvidia-580xx-utils \
        lib32-nvidia-580xx-utils \
        nvidia-settings

}

# ----------------------------------------------------------------------
# Audio stack
# ----------------------------------------------------------------------

install_audio(){

    info "Installing PipeWire"

    pacman -S --needed --noconfirm \
        pipewire \
        pipewire-alsa \
        pipewire-pulse \
        pipewire-jack \
        wireplumber

}

# ----------------------------------------------------------------------
# Bluetooth
# ----------------------------------------------------------------------

install_bluetooth(){

    info "Installing Bluetooth"

    pacman -S --needed --noconfirm \
        bluez \
        bluez-utils \
        bluedevil

    systemctl enable bluetooth

}

# ----------------------------------------------------------------------
# Desktop Environment
# ----------------------------------------------------------------------

install_kde(){

    info "Installing KDE Plasma"

    pacman -S --needed --noconfirm \
        plasma-meta \
        kde-applications-meta \
        sddm

    systemctl enable sddm

}

# ----------------------------------------------------------------------
# Gaming stack
# ----------------------------------------------------------------------

install_gaming(){

    info "Installing gaming stack"

    pacman -S --needed --noconfirm \
        steam \
        lutris \
        heroic-games-launcher \
        mangohud \
        lib32-mangohud \
        gamemode \
        lib32-gamemode \
        vulkan-tools \
        vulkan-icd-loader \
        lib32-vulkan-icd-loader \
        wine-staging \
        winetricks

}

# ----------------------------------------------------------------------
# Performance tools
# ----------------------------------------------------------------------

install_performance(){

    info "Installing performance tools"

    pacman -S --needed --noconfirm \
        ananicy-cpp \
        earlyoom \
        preload

    systemctl enable ananicy-cpp
    systemctl enable earlyoom

}

# ----------------------------------------------------------------------
# ZRAM
# ----------------------------------------------------------------------

setup_zram(){

    info "Configuring ZRAM"

    pacman -S --needed --noconfirm zram-generator

    cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF

}

# ----------------------------------------------------------------------
# Kernel tweaks
# ----------------------------------------------------------------------

apply_sysctl(){

    info "Applying kernel tweaks"

cat > /etc/sysctl.d/99-arch-performance.conf <<EOF
vm.swappiness=10
vm.max_map_count=2147483642
fs.file-max=2097152
kernel.sched_autogroup_enabled=1
EOF

    sysctl --system

}

# ----------------------------------------------------------------------
# AUR apps
# ----------------------------------------------------------------------

install_aur_apps(){

    info "Installing AUR utilities"

    sudo -u "$REAL_USER" paru -S --noconfirm \
        protonup-qt \
        goverlay \
        vkbasalt \
        vesktop \
        mission-center

}

# ----------------------------------------------------------------------
# Final
# ----------------------------------------------------------------------

finish(){

    echo
    ok "Arch setup finished"
    warn "Reboot your system"
    echo "Log saved at $LOGFILE"

}

# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------

main(){

    echo "===================================="
    echo "      ARCH ALL-IN-ONE SETUP"
    echo "===================================="

    detect_hardware
    enable_multilib
    optimize_pacman
    optimize_mirrors
    update_system
    install_base
    install_paru
    install_nvidia
    install_audio
    install_bluetooth
    install_kde
    install_gaming
    install_performance
    setup_zram
    install_aur_apps
    apply_sysctl
    finish

}

main
