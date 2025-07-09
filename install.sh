#!/bin/bash

############################################################################################################
# Script: install.sh
# Purpose: Automated setup for OSX-PROXMOX environment on Proxmox VE
# Source: https://luchina.com.br
# Author: luchina-gabriel (https://github.com/luchina-gabriel/OSX-PROXMOX)
############################################################################################################

clear

# Function to render a simple progress bar
progress_bar() {
    local percent=$1
    local bar=""
    for ((i=0; i<percent/2; i++)); do bar+="█"; done
    printf "\rProgress: [%-50s] %d%%" "$bar" "$percent"
}

echo "Initializing OSX-PROXMOX installation..."
sleep 1

TOTAL_STEPS=8
CURRENT_STEP=0

# Progress bar updater
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    progress_bar $((CURRENT_STEP * 100 / TOTAL_STEPS))
    sleep 0.3
}

# Initialize progress display
progress_bar 0
sleep 1

# Step 1: Cleanup previous installations
echo "[*] Cleaning up previous installation (if any)..."
rm -rf /root/OSX-PROXMOX
rm -f /etc/apt/sources.list.d/pve-enterprise.list
rm -f /etc/apt/sources.list.d/ceph.list
update_progress

# Step 2: Update system packages
echo -e "\n[*] Updating package lists..."
apt update > /tmp/install-osx-proxmox.log 2>&1
if [ $? -ne 0 ]; then
    echo "[!] 'apt update' failed. Attempting to fix mirrors..."

    # Auto-detect user's country for better mirror selection
    COUNTRY=$(curl -s https://ipinfo.io/country | tr '[:upper:]' '[:lower:]')
    MIRROR="ftp.${COUNTRY}.debian.org"

    if ! grep -q "$MIRROR" /etc/apt/sources.list; then
        echo "[*] Updating Debian mirror in sources.list..."
        sed -i "s|$MIRROR|ftp.debian.org|g" /etc/apt/sources.list
    fi

    echo "[*] Retrying 'apt update'..."
    apt update >> /tmp/install-osx-proxmox.log 2>&1
    if [ $? -ne 0 ]; then
        echo "[!] Failed to update package list even after adjusting mirrors. Aborting."
        exit 1
    fi
fi
update_progress

# Step 3: Install Git
echo "[*] Installing Git..."
apt install -y git >> /tmp/install-osx-proxmox.log 2>&1
update_progress

# Step 4: Clone OSX-PROXMOX repository
echo "[*] Cloning OSX-PROXMOX repository..."
git clone https://github.com/luchina-gabriel/OSX-PROXMOX.git /root/OSX-PROXMOX >> /tmp/install-osx-proxmox.log 2>&1
if [ $? -ne 0 ]; then
    echo "[!] Failed to clone the repository. Check your internet connection or GitHub availability."
    exit 1
fi
update_progress

# Step 5: Validate setup script presence
if [ ! -f /root/OSX-PROXMOX/setup ]; then
    echo "[!] Setup script not found in the repository. Aborting installation."
    exit 1
fi
update_progress

# Step 6: Make the setup script executable
chmod +x /root/OSX-PROXMOX/setup
update_progress

# Step 7: Run the setup
echo -e "\n[*] Executing OSX-PROXMOX setup script..."
cd /root/OSX-PROXMOX && ./setup
if [ $? -ne 0 ]; then
    echo -e "\n[!] An error occurred during setup. Please check the log at: /tmp/install-osx-proxmox.log"
    exit 1
fi
update_progress

# Step 8: Finalization
echo -e "\n[+] OSX-PROXMOX setup completed successfully!"
update_progress

echo -e "\nInstallation finished.\n"
