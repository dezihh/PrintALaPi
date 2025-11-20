#!/bin/bash
# Setup OverlayFS for read-only filesystem protection

# Note: We don't use 'set -e' to allow the script to continue even if some commands fail

echo "Setting up OverlayFS for read-only filesystem..."

# Install overlay-fs support
apt-get install -y overlayroot || echo "Warning: Could not install overlayroot package"

# Configure overlayroot
cat > /etc/overlayroot.conf <<'EOF'
# OverlayRoot configuration for PrintALaPi
# This protects the root filesystem from corruption during power loss

# Enable overlayroot
overlayroot="tmpfs:swap=1,recurse=0"

# Exclude certain directories that need to be writable
overlayroot_cfgdisk="disabled"
EOF

# Create directories that need to persist
mkdir -p /var/log.persist
mkdir -p /etc/cups.persist

# Update fstab to bind mount persistent directories
cat >> /etc/fstab <<'EOF'

# PrintALaPi persistent directories
tmpfs           /tmp            tmpfs   nosuid,nodev         0       0
tmpfs           /var/log        tmpfs   nosuid,nodev         0       0
tmpfs           /var/tmp        tmpfs   nosuid,nodev         0       0
EOF

# Create a script to toggle read-only mode
cat > /usr/local/bin/rw <<'EOF'
#!/bin/bash
# Enable read-write mode temporarily
mount -o remount,rw /
echo "Root filesystem is now read-write. Use 'ro' command to switch back."
EOF

cat > /usr/local/bin/ro <<'EOF'
#!/bin/bash
# Enable read-only mode
sync
mount -o remount,ro /
echo "Root filesystem is now read-only."
EOF

chmod +x /usr/local/bin/rw
chmod +x /usr/local/bin/ro

echo "OverlayFS configuration complete"
echo "The system will use a read-only root filesystem on next boot"
echo "Use 'rw' command to temporarily enable write access"
echo "Use 'ro' command to switch back to read-only mode"
