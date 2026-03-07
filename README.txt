Mi primer script para Arch Linux y hacerlo gamer.

Comandos a utilizar:

git clone https://github.com/Tony-855/arch-gaming-setup.git
cd arch-gaming-setup
chmod +x arch_gaming_setup.sh
./arch_gaming_setup.sh

¿Qué hace ahora el script?
- Valida dependencias básicas y confirma antes de modificar el sistema.
- Detecta CPU, GPU y bootloader automáticamente.
- Prepara multilib, aplica ajustes seguros de pacman y actualiza paquetes.
- Permite configurar Chaotic-AUR de forma opcional.
- Mantiene tu stack gamer (drivers NVIDIA 580xx, Proton GE, etc.) y añade una opción separada para audio/Bluetooth.

Recomendación:
- Reinicia al final para asegurar que módulos, kernel parameters y servicios queden aplicados.
