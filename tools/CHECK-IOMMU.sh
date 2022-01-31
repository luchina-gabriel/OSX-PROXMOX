#!/bin/bash
# 
# Script: check-iommu-enabled.sh
# Goal: Check if IOMMU are Enabled in your system
# 
# Author: Gabriel Luchina
# https://luchina.com.br
# 20220128T1112

if [ `dmesg | grep -e DMAR -e IOMMU | wc -l` -gt 0 ]
then
    echo "IOMMU Enabled"
else
    echo "IOMMU NOT Enabled"
    echo "Check file /etc/default/grub contains 'intel_iommu=on' in 'GRUB_CMDLINE_LINUX_DEFAULT' line"
fi
