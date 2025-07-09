#!/bin/bash
# 
# Script: IOMMU-Groups.sh
# Goal: List PCI devices in IOMMU Groups
# 
# Author: Gabriel Luchina
# https://luchina.com.br
# 20250627T2331

#!/bin/bash
shopt -s nullglob

for iommu_group in $(ls /sys/kernel/iommu_groups/ | sort -V); do
    echo "IOMMU Group ${iommu_group}:"
    for pci_device in /sys/kernel/iommu_groups/$iommu_group/devices/*; do
        echo -e "\t$(lspci -nns ${pci_device##*/})"
    done
done

