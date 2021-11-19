#!/bin/bash
# 
# Script: IOMMU-Groups.sh
# Goal: List PCI devices in IOMMU Groups
# 
# Author: Gabriel Luchina
# https://luchina.com.br
# 20211118T0010

shopt -s nullglob

for group in `ls /sys/kernel/iommu_groups/  | sort -V`
do
    echo "IOMMU Group ${group##*/}:"
    for device in /sys/kernel/iommu_groups/$group/devices/*
    do
        echo -e "\t$(lspci -nns ${device##*/})"
    done
done
