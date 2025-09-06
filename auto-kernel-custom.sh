#!/bin/bash
###############################################################################
# Gentoo Kernel Auto-Detect Script (Ultra Personalizado)
# Autor: Gerado por ChatGPT
# Objetivo: Detectar hardware PCI, habilitar apenas os drivers necessários e
# gerar kernel enxuto pronto para compilação.
###############################################################################

set -e

echo "==> Detectando hardware PCI..."
lspci -nnk > ~/pci-hardware.txt
echo "Lista completa salva em ~/pci-hardware.txt"

echo "==> Extraindo módulos sugeridos automaticamente..."
# Lista de módulos vazia inicial
MODULES=()

# Função auxiliar para detectar e adicionar módulos
detect_module() {
    local pattern="$1"
    local module="$2"
    if grep -qi "$pattern" ~/pci-hardware.txt; then
        MODULES+=("$module")
    fi
}

# Áudio
detect_module "Audio device.*Intel" "snd_hda_intel"
detect_module "Audio device.*Realtek" "snd_hda_intel"

# Wi-Fi
detect_module "Network controller.*Intel" "iwlwifi"
detect_module "Network controller.*Realtek" "rtlwifi"
detect_module "Network controller.*Qualcomm" "ath10k_pci"

# Ethernet
detect_module "Ethernet controller.*Intel" "e1000e"
detect_module "Ethernet controller.*Realtek" "r8169"

# GPU
detect_module "VGA compatible controller.*Intel" "i915"
detect_module "VGA compatible controller.*NVIDIA" "nouveau"
detect_module "VGA compatible controller.*AMD" "amdgpu"

# Storage
detect_module "SATA controller.*AHCI" "ahci"
detect_module "Non-Volatile memory controller" "nvme"

# Bluetooth
detect_module "Bluetooth" "btusb"

# Touchpad
detect_module "Touchpad|Elantech|Synaptics" "psmouse"

# Webcam
detect_module "Camera|Webcam|UVC" "uvcvideo"

# Mostrar módulos detectados
echo "==> Módulos detectados automaticamente:"
for mod in "${MODULES[@]}"; do
    echo "  - $mod"
done

# Entrar no diretório do kernel
cd /usr/src/linux || { echo "Erro: /usr/src/linux não encontrado"; exit 1; }

# Criar tinyconfig como base mínima
echo "==> Gerando tinyconfig como base mínima..."
make tinyconfig

# Habilitar módulos detectados
echo "==> Habilitando módulos essenciais..."
for mod in "${MODULES[@]}"; do
    scripts/config --enable "$mod" 2>/dev/null
done

# Salvar configuração final
cp .config ~/kernel-config-auto-custom.config
echo "Arquivo de configuração salvo em ~/kernel-config-auto-custom.config"

# Compilar kernel e módulos
echo "==> Compilando kernel e módulos..."
make -j"$(nproc)"
make modules_install
make install

# Gerar initramfs se genkernel estiver disponível
if command -v genkernel >/dev/null 2>&1; then
    echo "==> Gerando initramfs..."
    genkernel --install initramfs
fi

# Atualizar GRUB
echo "==> Atualizando GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg

# Mensagem final
echo "==> Kernel personalizado compilado e instalado com sucesso!"
echo "Arquivo de configuração: ~/kernel-config-auto-custom.config"
echo "Após reboot, verifique:"
echo "  uname -r            -> versão do kernel"
echo "  aplay -l / alsamixer -> áudio"
echo "  ip link / iwconfig   -> rede"
echo "  glxinfo | grep OpenGL -> GPU"
echo "  bluetoothctl list    -> Bluetooth"
echo "  xinput list          -> touchpad"

echo "==> Script finalizado."
