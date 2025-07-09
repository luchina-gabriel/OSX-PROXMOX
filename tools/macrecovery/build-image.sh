#!/bin/bash -e

# Script: create-recovery-disk.sh
# Author: Gabriel Luchina
# https://luchina.com.br 
# Description: Creates a Recovery DMG and converts it to raw for QEMU use

# Clean up on exit
cleanup() {
    echo "Cleaning up temporary files..."
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
if ! command -v hdiutil &>/dev/null; then
    echo "Error: hdiutil not found. Install macOS command-line tools." >&2
    exit 1
fi

if ! command -v qemu-img &>/dev/null; then
    echo "Error: qemu-img not found. Please install qemu-utils." >&2
    exit 1
fi

# Clean previous builds
echo "Removing old recovery disk files..."
rm -f "$SPARSE_IMAGE" "$OUTPUT_DMG" "$OUTPUT_RAW"

# Create sparse image
echo "Creating sparse disk image..."
hdiutil create -size 800m -layout "UNIVERSAL HD" -type SPARSE -o Recovery.dmg

# Mount the sparse image
echo "Mounting disk image..."
DEVICE=$(hdiutil attach -nomount "$SPARSE_IMAGE" | head -n 1 | awk '{print $1}')
echo "New device: $DEVICE"

# Partition the disk
echo "Partitioning disk..."
N=$(echo "$DEVICE" | tr -dc '0-9')
diskutil partitionDisk "$DEVICE" 1 MBR fat32 RECOVERY R
diskutil mount "disk${N}s1"

# Find mount point
MOUNT_POINT="$(diskutil info "disk${N}s1" | sed -n 's/.*Mount Point: *//p')"
echo "Mounted at: $MOUNT_POINT"

# Prepare Recovery folder
RECOVERY_FOLDER="$MOUNT_POINT/com.apple.recovery.boot"
mkdir -p "$RECOVERY_FOLDER"

# Copy required files
echo "Copying .dmg and .chunklist files to recovery partition..."
cp *.dmg *.chunklist "$RECOVERY_FOLDER/"

# Unmount and convert
echo "Unmounting and finalizing image..."
hdiutil detach "$DEVICE"
hdiutil convert -format UDZO "$SPARSE_IMAGE" -o "$OUTPUT_DMG"
rm -f "$SPARSE_IMAGE"

# Convert to raw format
echo "Converting DMG to RAW format..."
qemu-img convert -f dmg -O raw "$OUTPUT_DMG" "$OUTPUT_RAW"
rm -f "$OUTPUT_DMG"

echo "✅ Recovery disk created successfully!"
echo "Output file: $OUTPUT_RAW"
