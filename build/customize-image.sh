#!/bin/bash
set -e

# Script to customize Raspberry Pi OS image for PrintALaPi

IMAGE="raspios.img"
MOUNT_BOOT="/tmp/printalapy-boot"
MOUNT_ROOT="/tmp/printalapy-root"

echo "Setting up loop device..."
LOOP_DEVICE=$(sudo losetup -f --show -P "$IMAGE")
echo "Using loop device: $LOOP_DEVICE"

# Wait for partitions to be available
sleep 2

# Create mount points
sudo mkdir -p "$MOUNT_BOOT" "$MOUNT_ROOT"

# Mount partitions
echo "Mounting partitions..."
sudo mount "${LOOP_DEVICE}p1" "$MOUNT_BOOT"
sudo mount "${LOOP_DEVICE}p2" "$MOUNT_ROOT"

echo "Copying setup files to image..."

# Copy installation scripts
sudo mkdir -p "$MOUNT_ROOT/opt/printalapy"
sudo cp -r ../scripts/* "$MOUNT_ROOT/opt/printalapy/"
sudo cp -r ../config "$MOUNT_ROOT/opt/printalapy/"
sudo cp -r ../webserver "$MOUNT_ROOT/opt/printalapy/"

# Make scripts executable
sudo chmod +x "$MOUNT_ROOT/opt/printalapy/"*.sh
sudo chmod +x "$MOUNT_ROOT/opt/printalapy/webserver/"*.py

# Create systemd service for first boot setup
sudo tee "$MOUNT_ROOT/etc/systemd/system/printalapy-setup.service" > /dev/null <<EOF
[Unit]
Description=PrintALaPi First Boot Setup
After=network.target
Before=cups.service

[Service]
Type=oneshot
ExecStart=/opt/printalapy/setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo ln -sf /etc/systemd/system/printalapy-setup.service \
  "$MOUNT_ROOT/etc/systemd/system/multi-user.target.wants/printalapy-setup.service"

# Enable SSH by default
sudo touch "$MOUNT_BOOT/ssh"

echo "Unmounting partitions..."
sudo umount "$MOUNT_BOOT"
sudo umount "$MOUNT_ROOT"

# Detach loop device
sudo losetup -d "$LOOP_DEVICE"

# Rename the image
mv "$IMAGE" printalapy.img

echo "Image customization complete!"
