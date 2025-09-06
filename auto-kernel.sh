#!/bin/bash
###############################################################################
# Gentoo Kernel Auto-Config Script
# Autor: Gerado por ChatGPT
# Objetivo: Detectar hardware, gerar .config mínimo de kernel e compilar
###############################################################################

echo "==> Detectando hardware PCI..."
lspci -nnk > ~/pci-hardware.txt
echo "Lista completa salva em ~/pci-hardware.txt"

echo "==> Identificando módulos essenciais..."

# Detectar módulos baseados em dispositivos comuns (Intel/AMD/NVIDIA)
ESSENTIAL_MODULES=(
"snd_hda_intel"    # Áudio Intel/Realtek
"iwlwifi"          # Wi-Fi Intel
"e1000e"           # Ethernet Intel
"i915"             # GPU Intel
"nouveau"          # GPU NVIDIA open-source
"amdgpu"           # GPU AMD
"btusb"            # Bluetooth
"psmouse"          # Touchpad
"uvcvideo"         # Webcam USB
"ahci"             # SATA
"nvme"             # NVMe SSD
)

echo "Módulos essenciais detectados/pre-selecionados:"
for mod in "${ESSENTIAL_MODULES[@]}"; do
    echo "  - $mod"
done

echo "==> Preparando diretório do kernel..."
cd /usr/src/linux || { echo "Erro: diretório /usr/src/linux não encontrado"; exit 1; }

echo "==> Gerando tinyconfig como base mínima..."
make tinyconfig

echo "==> Habilitando módulos essenciais..."
for mod in "${ESSENTIAL_MODULES[@]}"; do
    scripts/config --enable "$mod" 2>/dev/null
done

echo "==> Salvando configuração final..."
cp .config ~/kernel-config-auto.config
echo "Arquivo de configuração salvo em ~/kernel-config-auto.config"

echo "==> Compilando kernel e módulos (paralelo)..."
make -j"$(nproc)"
make modules_install
make install

echo "==> Gerando initramfs (se necessário)..."
if command -v genkernel >/dev/null 2>&1; then
    genkernel --install initramfs
fi

echo "==> Atualizando GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "==> Concluído! Reinicie o sistema e verifique o kernel:"
echo "uname -r"
echo "Use 'aplay -l', 'ip link', 'iwconfig', 'glxinfo' e 'xinput list' para testar hardware"

echo "Arquivo de configuração de kernel automatizado salvo em ~/kernel-config-auto.config"
echo "==> Script finalizado."
