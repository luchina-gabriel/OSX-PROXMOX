#!/bin/bash

#########################################################################################################################
#
# Script: install
#
# https://luchina.com.br
#
#########################################################################################################################

apt update > /dev/null 2>> /dev/null
apt install git -y > /dev/null 2>> /dev/null

git clone https://github.com/luchina-gabriel/OSX-PROXMOX.git > /dev/null 2>> /dev/null

if [ ! -e /root/OSX-PROXMOX ]; then mkdir -p /root/OSX-PROXMOX; fi;

/root/OSX-PROXMOX/setup
