#!/bin/bash
###############################################################################
# Gentoo Kernel Ultra-Otimizado Auto-Detect
# Autor: Gerado por ChatGPT
# Objetivo: Detectar hardware completo e gerar kernel mínimo funcional,
# incluindo GPUs híbridas, Wi-Fi dual-band, NVMe+SATA e periféricos essenciais
###############################################################################

set -e

echo "==> Detectando hardware PCI..."
lspci -nnk > ~/pci-hardware.txt
echo "Lista completa salva em ~/pci-hardware.txt"

MODULES=()

# Função para detectar módulos automaticamente
detect_module() {
    local pattern="$1"
    local module="$2"
    if grep -qi "$pattern" ~/pci-hardware.txt; then
        MODULES+=("$module")
    fi
}

echo "==> Detectando dispositivos principais..."

# Áudio
detect_module "Audio device.*Intel" "snd_hda_intel"
detect_module "Audio device.*Realtek" "snd_hda_intel"

# Wi-Fi dual-band
detect_module "Network controller.*Intel" "iwlwifi"
detect_module "Network controller.*Realtek" "rtlwifi"
detect_module "Network controller.*Qualcomm" "ath10k_pci"

# Ethernet
detect_module "Ethernet controller.*Intel" "e1000e"
detect_module "Ethernet controller.*Realtek" "r8169"

# GPU híbrida (Intel + NVIDIA/AMD)
detect_module "VGA compatible controller.*Intel" "i915"
detect_module "VGA compatible controller.*NVIDIA" "nouveau"
detect_module "VGA compatible controller.*AMD" "amdgpu"

# Storage NVMe + SATA
detect_module "Non-Volatile memory controller" "nvme"
detect_module "SATA controller.*AHCI" "ahci"

# Bluetooth
detect_module "Bluetooth" "btusb"

# Touchpad
detect_module "Touchpad|Elantech|Synaptics" "psmouse"

# Webcam
detect_module "Camera|Webcam|UVC" "uvcvideo"

echo "==> Módulos detectados automaticamente:"
for mod in "${MODULES[@]}"; do
    echo "  - $mod"
done

# Entrar no diretório do kernel
cd /usr/src/linux || { echo "Erro: /usr/src/linux não encontrado"; exit 1; }

# Base mínima com tinyconfig
echo "==> Gerando tinyconfig..."
make tinyconfig

# Habilitar módulos detectados
echo "==> Habilitando módulos essenciais..."
for mod in "${MODULES[@]}"; do
    scripts/config --enable "$mod" 2>/dev/null
done

# Salvar configuração final
cp .config ~/kernel-config-ultra-custom.config
echo "Arquivo de configuração salvo em ~/kernel-config-ultra-custom.config"

# Compilar kernel e módulos
echo "==> Compilando kernel e módulos..."
make -j"$(nproc)"
make modules_install
make install

# Gerar initramfs se genkernel disponível
if command -v genkernel >/dev/null 2>&1; then
    echo "==> Gerando initramfs..."
    genkernel --install initramfs
fi

# Atualizar GRUB
echo "==> Atualizando GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg

# Checagem pós-boot
echo "==> Script concluído! Após reboot, verifique:"
echo "Kernel: uname -r"
echo "Áudio: aplay -l | alsamixer"
echo "Rede: ip link | iwconfig"
echo "GPU: glxinfo | grep OpenGL"
echo "Bluetooth: bluetoothctl list"
echo "Touchpad: xinput list"

echo "==> Kernel ultra-otimizado criado com sucesso!"
