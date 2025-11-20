#!/bin/bash
# Main setup script for PrintALaPi
# This script runs on first boot and configures the Raspberry Pi as a print server

set -e

INSTALL_DIR="/opt/printalapy"
LOG_FILE="/var/log/printalapy-setup.log"

echo "=== PrintALaPi Setup Started ===" | tee -a "$LOG_FILE"
date | tee -a "$LOG_FILE"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Update package list
log "Updating package list..."
apt-get update >> "$LOG_FILE" 2>&1

# Install required packages
log "Installing required packages..."
apt-get install -y \
    cups \
    cups-bsd \
    snmp \
    snmpd \
    dnsmasq \
    hostapd \
    python3 \
    python3-pip \
    python3-flask \
    iptables \
    >> "$LOG_FILE" 2>&1

# Setup CUPS
log "Configuring CUPS..."
bash "$INSTALL_DIR/setup-cups.sh" >> "$LOG_FILE" 2>&1

# Setup SNMP
log "Configuring SNMP..."
bash "$INSTALL_DIR/setup-snmp.sh" >> "$LOG_FILE" 2>&1

# Setup Captive Portal
log "Configuring Captive Portal..."
bash "$INSTALL_DIR/setup-portal.sh" >> "$LOG_FILE" 2>&1

# Setup Web Server
log "Configuring Web Server..."
bash "$INSTALL_DIR/setup-webserver.sh" >> "$LOG_FILE" 2>&1

# Setup OverlayFS (Read-only filesystem)
log "Configuring Read-only filesystem with OverlayFS..."
bash "$INSTALL_DIR/setup-overlayfs.sh" >> "$LOG_FILE" 2>&1

log "PrintALaPi setup completed successfully!"
log "System will reboot in 10 seconds..."

# Disable this service so it doesn't run again
systemctl disable printalapy-setup.service

sleep 10
reboot
