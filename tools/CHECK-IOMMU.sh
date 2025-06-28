#!/bin/bash
# 
# Script: check-iommu-enabled.sh
# Goal: Check if IOMMU is enabled on your system
# 
# Author: Gabriel Luchina
# https://luchina.com.br
# 20220128T1112

# Check for IOMMU or DMAR messages in dmesg
iommu_check=$(dmesg | grep -E 'DMAR|IOMMU')

if [ -n "$iommu_check" ]; then
    echo "IOMMU Enabled"
else
    echo "IOMMU NOT Enabled"
    echo "Ensure 'intel_iommu=on' or 'amd_iommu=on' is present in the 'GRUB_CMDLINE_LINUX_DEFAULT' line of /etc/default/grub"
    exit 1
fi

