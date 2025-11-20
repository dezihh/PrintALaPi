#!/bin/bash
# Setup SNMP monitoring for printers

# Note: We don't use 'set -e' to allow the script to continue even if some commands fail

echo "Setting up SNMP monitoring..."

# Backup original configuration
cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.backup

# Configure SNMP daemon
cat > /etc/snmp/snmpd.conf <<'EOF'
# SNMP configuration for PrintALaPi

# System information
sysLocation    PrintALaPi Print Server
sysContact     admin@printalapy
sysServices    72

# Listen on all interfaces
agentAddress udp:161,udp6:[::1]:161

# Access control
rocommunity public default
rocommunity6 public default

# System information
sysdescr PrintALaPi - Raspberry Pi Print Server

# Enable monitoring of printers
extend printer-status /opt/printalapy/check-printer-status.sh

# Include disk and CPU monitoring
includeAllDisks 10%
load 12 14 14

# Process monitoring
proc cupsd
proc snmpd
EOF

# Create printer status check script
cat > /opt/printalapy/check-printer-status.sh <<'EOF'
#!/bin/bash
# Check status of all configured printers via CUPS

lpstat -p -d 2>/dev/null | grep -E "printer|idle|printing|disabled" | head -10 || echo "No printers configured"
EOF

chmod +x /opt/printalapy/check-printer-status.sh

# Enable SNMP service (this works in chroot)
systemctl enable snmpd || true

# Try to restart SNMP service (this will fail in chroot but work on real system)
systemctl restart snmpd 2>/dev/null || echo "Note: SNMP service will start on first boot"

echo "SNMP configuration complete"
