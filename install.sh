#!/bin/bash

#########################################################################################################################
#
# Script: install
#
# https://luchina.com.br
#
#########################################################################################################################

apt update > /tmp/install-osx-proxmox.log 2>> /tmp/install-osx-proxmox.log
apt install git -y >> /tmp/install-osx-proxmox.log 2>> /tmp/install-osx-proxmox.log

git clone https://github.com/luchina-gabriel/OSX-PROXMOX.git >> /tmp/install-osx-proxmox.log 2>> /tmp/install-osx-proxmox.log

if [ $? -ne 0 ]; then echo "Problem to clone repository from GitHub"; exit; fi;

if [ ! -e /root/OSX-PROXMOX ]; then mkdir -p /root/OSX-PROXMOX; fi;

/root/OSX-PROXMOX/setup
