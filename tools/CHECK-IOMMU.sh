#!/bin/bash
# 
# Script: check-iommu-enabled.sh
# Goal: Check if IOMMU is enabled in the system
# 
# Author: Gabriel Luchina
# https://luchina.com.br   
# 20220128T1112
# Updated: 2025-04-06
#

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Предупреждение: Рекомендуется запускать от root для полного доступа.${NC}"
fi

echo "Checking if IOMMU is enabled..."

# Check dmesg output for IOMMU-related messages
iommu_check=$(dmesg | grep -i -E 'iommu|DMAR|amd-vi')

if [[ -n "$iommu_check" ]]; then
    echo -e "${GREEN}✅ IOMMU активирован в ядре!${NC}"
    echo
    echo "Найденные записи:"
    echo "$iommu_check"
else
    echo -e "${RED}❌ IOMMU не обнаружен или выключен.${NC}"
    echo
    echo -e "${YELLOW}Возможные причины:${NC}"
    echo "1. В BIOS/UEFI отключена поддержка IOMMU (SVM Mode для AMD / VT-d для Intel)"
    echo "2. Не добавлен параметр загрузки ядра:"
    echo "   Для Intel: intel_iommu=on"
    echo "   Для AMD: amd_iommu=on"
    echo "   Добавьте их в GRUB_CMDLINE_LINUX_DEFAULT в /etc/default/grub"
    echo "   Затем выполните: update-grub"
fi
