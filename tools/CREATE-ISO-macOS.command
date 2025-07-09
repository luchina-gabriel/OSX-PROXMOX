#!/bin/bash

# 
# Script: create-iso-macOS.sh
# Goal: Create macOS ISO-like image for use in Proxmox VE
# 
# Author: Gabriel Luchina
# https://luchina.com.br   
# Updated: 2025-04-06
#

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

clear

echo -e "${GREEN}Automate script for creating macOS Install ISO for Proxmox VE${NC}"
echo -e "BY: ${YELLOW}https://luchina.com.br ${NC}"
echo -e "SUPPORT: ${YELLOW}https://osx-proxmox.com ${NC}"

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[!] Рекомендуется запускать от root для корректной работы.${NC}"
    echo -e "Продолжить как обычный пользователь? (y/n)"
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "Выход."
        exit 1
    fi
fi

# Ask for temp directory
read -p $'\n'"Введите путь к рабочей директории (work dir): " TEMPDIR
if [ ! -d "$TEMPDIR" ]; then
    echo -e "${RED}[!] Указанная директория не существует.${NC}"
    exit 1
fi

# Ask for macOS app path
read -p "Введите путь к macOS Installer (.app): " APPOSX
if [ ! -d "$APPOSX" ]; then
    echo -e "${RED}[!] Указанный .app файл не найден.${NC}"
    exit 1
fi

cd "$TEMPDIR" || { echo -e "${RED}[!] Не могу перейти в указанную директорию.${NC}"; exit 1; }

# Clean up previous files
echo -e "\n${YELLOW}[*] Очистка старых файлов...${NC}"
rm -rf macOS-install.dmg* > /dev/null 2>&1

# Create DMG
echo -e "${YELLOW}[*] Создание временного дискового образа...${NC}"
hdiutil create -o macOS-install.dmg -size 16g -layout GPTSPUD -fs HFS+J > /dev/null 2>&1

# Mount DMG
echo -e "${YELLOW}[*] Подключение образа...${NC}"
hdiutil verify macOS-install.dmg > /dev/null 2>&1
hdiutil mount macOS-install.dmg > /dev/null 2>&1
MOUNT_POINT="/Volumes/install_build"

# Run createinstallmedia
echo -e "${YELLOW}[*] Заливка macOS установщика в образ... Это может занять несколько минут.${NC}"
sudo "$APPOSX/Contents/Resources/createinstallmedia" --volume "$MOUNT_POINT" --nointeraction

# Unmount volumes
echo -e "${YELLOW}[*] Отключение томов...${NC}"
diskutil list | grep "Install macOS" | awk '{print $1}' | xargs -I {} hdiutil detach {} > /dev/null 2>&1
sleep 3

# Convert to ISO-style file
echo -e "${YELLOW}[*] Конвертация в формат ISO...${NC}"
mv macOS-install.dmg macOS-install.iso

# Final message
echo -e "\n${GREEN}[✓] Готово! Образ создан:${NC}"
echo "Файл: macOS-install.iso"
echo "Теперь вы можете загрузить его в Proxmox как CD-ROM (VirtIO или IDE)."
