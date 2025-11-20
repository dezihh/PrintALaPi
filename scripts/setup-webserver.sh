#!/bin/bash
# Setup web server for PrintALaPi configuration

# Note: We don't use 'set -e' to allow the script to continue even if some commands fail

echo "Setting up configuration web server..."

# Create systemd service for the web server
cat > /etc/systemd/system/printalapy-web.service <<'EOF'
[Unit]
Description=PrintALaPi Configuration Web Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/printalapy/webserver
ExecStart=/usr/bin/python3 /opt/printalapy/webserver/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable the service (daemon-reload and enable work in chroot)
systemctl daemon-reload || true
systemctl enable printalapy-web.service || true

# Try to start the service (this will fail in chroot but work on real system)
systemctl start printalapy-web.service 2>/dev/null || echo "Note: Web server will start on first boot"

echo "Web server configuration complete"
