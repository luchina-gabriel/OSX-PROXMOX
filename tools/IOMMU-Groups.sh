#!/bin/bash
#
# Script: IOMMU-Groups.sh
# Goal: List PCI devices in IOMMU Groups (no color output)
#
# Author: Gabriel Luchina
# https://luchina.com.br
# Original: 20211118T0010
# Updated: 2025-04-05
#

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Warning: It is recommended to run as root for full access."
  echo "Press Enter to continue as a regular user, or CTRL+C to exit..."
  read -r
fi

shopt -s nullglob

echo "IOMMU Group Devices:"

for group in $(ls /sys/kernel/iommu_groups/ | sort -V); do
    group_num=$(echo "$group" | sed 's/[^0-9]*//g')
    echo "Group $group_num:"
    for device in /sys/kernel/iommu_groups/$group/devices/*; do
        dev_id="${device##*/}"
        info=$(lspci -nns "$dev_id" 2>/dev/null || true)
        if [[ -z "$info" ]]; then
            echo -e "\t$dev_id (Unable to get info)"
        else
            echo -e "\t$info"
        fi
    done
done
