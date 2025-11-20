#!/bin/bash
# Diagnostic report script for PrintALaPi
# Generates a comprehensive system report for troubleshooting

echo "=== PrintALaPi Diagnostic Report ==="
echo "Generated: $(date)"
echo ""

echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo "Uptime: $(uptime -p)"
echo "Hardware: $(cat /proc/cpuinfo | grep Model | cut -d: -f2 | xargs)"
echo ""

echo "=== Network Configuration ==="
echo "IP Addresses:"
ip addr show | grep -E "inet |inet6 " | awk '{print $2}'
echo ""
echo "Network Interfaces:"
ls /sys/class/net/
echo ""
echo "Wireless Interface Status:"
iwconfig 2>&1 | grep -v "no wireless"
echo ""

echo "=== Service Status ==="
services="cups snmpd hostapd dnsmasq printalapy-web"
for service in $services; do
    echo "Service: $service"
    systemctl is-active $service
    echo ""
done

echo "=== CUPS Configuration ==="
echo "CUPS Version: $(cups-config --version 2>/dev/null || echo 'Not found')"
echo "Printers:"
lpstat -p 2>/dev/null || echo "No printers configured"
echo ""
echo "Print Queue:"
lpstat -o 2>/dev/null || echo "No jobs in queue"
echo ""

echo "=== Disk Usage ==="
df -h | grep -E "Filesystem|/dev/root|/dev/mmcblk"
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== CPU Load ==="
uptime
echo ""

echo "=== Recent Errors (last 20 lines) ==="
echo "--- CUPS Errors ---"
tail -20 /var/log/cups/error_log 2>/dev/null || echo "No CUPS error log found"
echo ""

echo "--- System Errors ---"
journalctl -p err -n 20 --no-pager 2>/dev/null || echo "Cannot read journal"
echo ""

echo "=== Port Status ==="
echo "Listening ports:"
sudo netstat -tulpn 2>/dev/null | grep LISTEN | awk '{print $4 " - " $7}' || ss -tulpn | grep LISTEN
echo ""

echo "=== PrintALaPi Configuration ==="
if [ -f /opt/printalapy/config/printalapy.conf ]; then
    cat /opt/printalapy/config/printalapy.conf
else
    echo "Configuration file not found"
fi
echo ""

echo "=== OverlayFS Status ==="
mount | grep overlay || echo "OverlayFS not active"
echo ""

echo "=== End of Diagnostic Report ==="
