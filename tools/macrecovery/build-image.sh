#!/bin/bash -e

# Script: create-recovery-disk.sh
# Author: Gabriel Luchina
# https://luchina.com.br 
# Description: Creates a macOS Recovery DMG and converts it to raw for QEMU use

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Clean up on exit
cleanup() {
    echo -e "${YELLOW}[*] Cleaning up temporary files...${NC}"
    hdiutil verify "$SPARSE_IMAGE" &>/dev/null || true
    hdiutil detach "$DEVICE" &>/dev/null || true
    rm -f "$SPARSE_IMAGE" "$OUTPUT_DMG" &>/dev/null || true
}
trap cleanup EXIT

# Constants
SPARSE_IMAGE="Recovery.dmg.sparseimage"
OUTPUT_DMG="Recovery.RO.dmg"
OUTPUT_RAW="Recovery.RO.raw"

# Check prerequisites
echo -e "${YELLOW}[*] Checking prerequisites...${NC}"
if ! command -v hdiutil &>/dev/null; then
    echo -e "${RED}[!] hdiutil not found. Install macOS command-line tools.${NC}"
    exit 1
fi

if ! command -v qemu-img &>/dev/null; then
    echo -e "${RED}[!] qemu-img not found. Please install qemu-utils.${NC}"
    exit 1
fi

# Clean previous builds
echo -e "${YELLOW}[*] Removing old recovery disk files...${NC}"
rm -f "$SPARSE_IMAGE" "$OUTPUT_DMG" "$OUTPUT_RAW" > /dev/null 2>&1 || true

# Create sparse image
echo -e "${YELLOW}[*] Creating sparse disk image...${NC}"
hdiutil create -size 800m -layout "UNIVERSAL HD" -type SPARSE -o Recovery.dmg > /dev/null

# Mount the sparse image
echo -e "${YELLOW}[*] Mounting disk image...${NC}"
DEVICE=$(hdiutil attach -nomount "$SPARSE_IMAGE" | head -n 1 | awk '{print $1}')
echo -e "${YELLOW}[*] New device: ${GREEN}${DEVICE}${NC}"

# Partition the disk
echo -e "${YELLOW}[*] Partitioning disk...${NC}"
N=$(echo "$DEVICE" | tr -dc '0-9')
diskutil partitionDisk "$DEVICE" 1 MBR fat32 RECOVERY R > /dev/null
diskutil mount "disk${N}s1" > /dev/null

# Find mount point
MOUNT_POINT="$(diskutil info "disk${N}s1" | sed -n 's/.*Mount Point: *//p')"
echo -e "${YELLOW}[*] Mounted at: ${GREEN}${MOUNT_POINT}${NC}"

# Prepare Recovery folder
RECOVERY_FOLDER="$MOUNT_POINT/com.apple.recovery.boot"
mkdir -p "$RECOVERY_FOLDER"

# Find BaseSystem.dmg and .chunklist
echo -e "${YELLOW}[*] Searching for macOS recovery files...${NC}"
DMG_FILE=$(find . -maxdepth 1 -name "*.dmg" -not -name "*Recovery*" | head -n 1)
CHUNKLIST_FILE=$(find . -maxdepth 1 -name "*.chunklist" | head -n 1)

if [[ -z "$DMG_FILE" ]]; then
    echo -e "${RED}[!] BaseSystem.dmg or equivalent not found in current directory.${NC}"
    exit 1
fi

if [[ -z "$CHUNKLIST_FILE" ]]; then
    echo -e "${YELLOW}[!] .chunklist file not found, continuing without it...${NC}"
fi

# Copy required files
echo -e "${YELLOW}[*] Copying files to recovery partition...${NC}"
cp "$DMG_FILE" "$RECOVERY_FOLDER/"

if [[ -n "$CHUNKLIST_FILE" ]]; then
    cp "$CHUNKLIST_FILE" "$RECOVERY_FOLDER/"
fi

# Unmount and convert
echo -e "${YELLOW}[*] Unmounting and finalizing image...${NC}"
hdiutil detach "$DEVICE" > /dev/null
hdiutil convert -format UDZO "$SPARSE_IMAGE" -o "$OUTPUT_DMG" > /dev/null
rm -f "$SPARSE_IMAGE"

# Convert to raw format
echo -e "${YELLOW}[*] Converting DMG to RAW format...${NC}"
qemu-img convert -f dmg -O raw "$OUTPUT_DMG" "$OUTPUT_RAW" > /dev/null
rm -f "$OUTPUT_DMG"

# Done!
echo -e "\n${GREEN}✅ Recovery disk created successfully!${NC}"
echo -e "Output file: ${GREEN}${OUTPUT_RAW}${NC}"
