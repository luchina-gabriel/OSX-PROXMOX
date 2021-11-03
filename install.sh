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

/root/OSX-PROXMOX/setup
