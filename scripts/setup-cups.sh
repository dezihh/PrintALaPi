#!/bin/bash
# Setup CUPS print server

# Note: We don't use 'set -e' to allow the script to continue even if some commands fail

echo "Setting up CUPS print server..."

# Backup original configuration
cp /etc/cups/cupsd.conf /etc/cups/cupsd.conf.backup

# Configure CUPS to accept connections from network
cat > /etc/cups/cupsd.conf <<'EOF'
# CUPS configuration for PrintALaPi
LogLevel warn
MaxLogSize 0
PageLogFormat

# Listen on all interfaces
Port 631
Listen /run/cups/cups.sock

# Share printers on the local network
Browsing On
BrowseLocalProtocols dnssd

# Default authentication type
DefaultAuthType Basic
DefaultEncryption Never

# Web interface
WebInterface Yes

# Restrict access to the server
<Location />
  Order allow,deny
  Allow all
</Location>

# Restrict access to the admin pages
<Location /admin>
  Order allow,deny
  Allow @LOCAL
</Location>

# Restrict access to configuration files
<Location /admin/conf>
  AuthType Basic
  Require user @SYSTEM
  Order allow,deny
  Allow @LOCAL
</Location>

# Set the default printer-op policy
<Policy default>
  JobPrivateAccess default
  JobPrivateValues default
  SubscriptionPrivateAccess default
  SubscriptionPrivateValues default

  <Limit All>
    Order deny,allow
  </Limit>

  <Limit Send-Document Send-URI Hold-Job Release-Job Restart-Job Purge-Jobs Set-Job-Attributes Create-Job-Subscription Renew-Subscription Cancel-Subscription Get-Notifications Reprocess-Job Cancel-Current-Job Suspend-Current-Job Resume-Job Cancel-My-Jobs Close-Job CUPS-Move-Job CUPS-Get-Document>
    Require user @OWNER @SYSTEM
    Order deny,allow
  </Limit>

  <Limit CUPS-Add-Modify-Printer CUPS-Delete-Printer CUPS-Add-Modify-Class CUPS-Delete-Class CUPS-Set-Default CUPS-Get-Devices>
    AuthType Basic
    Require user @SYSTEM
    Order deny,allow
  </Limit>

  <Limit Pause-Printer Resume-Printer Enable-Printer Disable-Printer Pause-Printer-After-Current-Job Hold-New-Jobs Release-Held-New-Jobs Deactivate-Printer Activate-Printer Restart-Printer Shutdown-Printer Startup-Printer Promote-Job Schedule-Job-After Cancel-Jobs CUPS-Accept-Jobs CUPS-Reject-Jobs>
    AuthType Basic
    Require user @SYSTEM
    Order deny,allow
  </Limit>

  <Limit Cancel-Job CUPS-Authenticate-Job>
    Require user @OWNER @SYSTEM
    Order deny,allow
  </Limit>

  <Limit All>
    Order deny,allow
  </Limit>
</Policy>
EOF

# Add cups user to lpadmin group
usermod -a -G lpadmin pi || true

# Enable CUPS service (this works in chroot)
systemctl enable cups || true

# Try to restart CUPS service (this will fail in chroot but work on real system)
systemctl restart cups 2>/dev/null || echo "Note: CUPS service will start on first boot"

echo "CUPS configuration complete"
