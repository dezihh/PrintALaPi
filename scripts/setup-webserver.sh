#!/bin/bash
# Setup web server for PrintALaPi configuration

set -e

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

# Enable and start the service
systemctl daemon-reload
systemctl enable printalapy-web.service
systemctl start printalapy-web.service

echo "Web server configuration complete"
