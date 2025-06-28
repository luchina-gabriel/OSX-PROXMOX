#!/bin/bash

#########################################################################################################################
#
# Script: install
# Purpose: Install OSX-PROXMOX
# Source: https://luchina.com.br
#
#########################################################################################################################

# Exit on any error
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

# Define log file
LOG_FILE="/root/install-osx-proxmox.log"

# Function to log messages
log_message() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Function to check command success
check_status() {
    if [ $? -ne 0 ]; then
        log_message "Error: $1"
        exit 1
    fi
}

# Clear screen
clear

# Clean up existing files
log_message "Cleaning up existing files..."
[ -d "/root/OSX-PROXMOX" ] && rm -rf "/root/OSX-PROXMOX"
[ -f "/etc/apt/sources.list.d/pve-enterprise.list" ] && rm -f "/etc/apt/sources.list.d/pve-enterprise.list"
[ -f "/etc/apt/sources.list.d/ceph.list" ] && rm -f "/etc/apt/sources.list.d/ceph.list"

log_message "Preparing to install OSX-PROXMOX..."

# Update package lists
log_message "Updating package lists..."
apt-get update >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log_message "Initial apt-get update failed. Attempting to fix sources..."
    
    # Use main Debian mirror instead of country-specific
    sed -i 's/ftp\.[a-z]\{2\}\.debian\.org/ftp.debian.org/g' /etc/apt/sources.list
    
    log_message "Retrying apt-get update..."
    apt-get update >> "$LOG_FILE" 2>&1
    check_status "Failed to update package lists after source modification"
fi

# Install git
log_message "Installing git..."
apt-get install -y git >> "$LOG_FILE" 2>&1
check_status "Failed to install git"

# Clone repository
log_message "Cloning OSX-PROXMOX repository..."
git clone https://github.com/luchina-gabriel/OSX-PROXMOX.git /root/OSX-PROXMOX >> "$LOG_FILE" 2>&1
check_status "Failed to clone repository"

# Ensure directory exists and setup is executable
if [ -f "/root/OSX-PROXMOX/setup" ]; then
    chmod +x "/root/OSX-PROXMOX/setup"
    log_message "Running setup script..."
    /root/OSX-PROXMOX/setup 2>&1 | tee -a "$LOG_FILE" 
    check_status "Failed to run setup script"
else
    log_message "Error: Setup script not found in /root/OSX-PROXMOX"
    exit 1
fi

log_message "Installation completed successfully"