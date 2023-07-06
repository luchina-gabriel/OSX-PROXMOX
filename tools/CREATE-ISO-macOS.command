#!/bin/bash
# 
# Script: create-iso-macOS
# Goal: create "ISO" file for use in the Proxmox VE Environment
# 
# Author: Gabriel Luchina
# https://luchina.com.br
# 20211116T2245

clear

echo -e "\nAutomate script for create \"ISO\" file of macOS Install in Proxmox VE Environament"
echo -e "BY: https://luchina.com.br"
echo -e "SUPPORT: https://osx-proxmox.com"

echo -n -e "\nPath to temporary files (work dir): "
read TEMPDIR

echo -n -e "Path to macOS Installation (.app) file: "
read APPOSX

echo " "

## Core 
cd ${TEMPDIR} > /dev/null 2> /dev/null
rm -rf macOS-install* > /dev/null 2> /dev/null
hdiutil create -o macOS-install -size 15g -layout GPTSPUD -fs HFS+J > /dev/null 2> /dev/null
hdiutil attach -noverify -mountpoint /Volumes/install_build macOS-install.dmg > /dev/null 2> /dev/null
sudo "${APPOSX}/Contents/Resources/createinstallmedia" --volume /Volumes/install_build --nointeraction
hdiutil detach -force "/Volumes/Install macOS"* > /dev/null 2> /dev/null && sleep 3s > /dev/null 2> /dev/null
hdiutil detach -force "/Volumes/Shared Support"* > /dev/null 2> /dev/null
mv macOS-install.dmg macOS-install.iso > /dev/null 2> /dev/null

echo " "
