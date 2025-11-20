# Troubleshooting Guide

This guide helps you diagnose and fix common issues with PrintALaPi.

## Diagnostic Steps

### 1. Check System Status

```bash
# Check all services
systemctl status cups
systemctl status snmpd
systemctl status hostapd
systemctl status dnsmasq
systemctl status printalapy-web

# Check system resources
free -h
df -h
top
```

### 2. Review Logs

```bash
# CUPS logs
tail -f /var/log/cups/error_log
tail -f /var/log/cups/access_log

# System logs
journalctl -xe
journalctl -u cups
journalctl -u printalapy-web

# Setup log
cat /var/log/printalapy-setup.log
```

### 3. Network Diagnostics

```bash
# Check network interfaces
ip addr show
ifconfig

# Check connectivity
ping -c 4 8.8.8.8
ping -c 4 google.com

# Check open ports
sudo netstat -tulpn
ss -tulpn
```

## Common Issues

### Issue: System Won't Boot

**Symptoms:**
- Raspberry Pi LEDs show no activity
- No output on connected display
- Cannot connect via network

**Diagnosis:**
1. Check power LED - should be solid red
2. Check activity LED - should blink during boot
3. Check SD card is properly inserted
4. Verify power supply provides adequate current (2.5A minimum)

**Solutions:**

```bash
# Test with different SD card
# Try re-flashing the image
# Use official Raspberry Pi power supply
# Check for corrupted SD card
```

### Issue: Cannot Connect to Wi-Fi Access Point

**Symptoms:**
- "PrintALaPi-Setup" SSID not visible
- Cannot authenticate with password
- Connection drops frequently

**Diagnosis:**

```bash
# Check wireless interface
iwconfig

# Check hostapd status
systemctl status hostapd

# Check hostapd logs
journalctl -u hostapd

# Verify wireless interface is not blocked
rfkill list
```

**Solutions:**

```bash
# Unblock wireless if blocked
sudo rfkill unblock wifi

# Restart hostapd
sudo systemctl restart hostapd

# Check hostapd configuration
sudo rw
sudo cat /etc/hostapd/hostapd.conf

# Verify wireless interface exists
ls /sys/class/net/

# Reconfigure if needed
sudo bash /opt/printalapy/setup-portal.sh
sudo ro
```

### Issue: CUPS Web Interface Not Accessible

**Symptoms:**
- "Connection refused" error
- "Forbidden" error
- Page times out

**Diagnosis:**

```bash
# Check CUPS is running
systemctl status cups

# Check CUPS is listening
sudo netstat -tulpn | grep 631

# Test local connection
curl http://localhost:631

# Check firewall rules
sudo iptables -L
```

**Solutions:**

```bash
# Restart CUPS
sudo systemctl restart cups

# Verify CUPS configuration
sudo rw
sudo cat /etc/cups/cupsd.conf

# Reset CUPS configuration
sudo cp /etc/cups/cupsd.conf.backup /etc/cups/cupsd.conf
sudo systemctl restart cups

# Allow through firewall
sudo iptables -A INPUT -p tcp --dport 631 -j ACCEPT
sudo ro
```

### Issue: Printer Not Detected

**Symptoms:**
- USB printer not showing in CUPS
- Network printer not found
- "No printers found" message

**Diagnosis:**

```bash
# Check USB devices
lsusb

# Check available printers
lpinfo -v

# Check CUPS error log
tail -f /var/log/cups/error_log

# Verify printer is powered on
# Check USB cable connection
```

**Solutions:**

```bash
# For USB printers:
# 1. Unplug and replug USB cable
# 2. Try different USB port
# 3. Check printer is powered on

# Restart CUPS to detect new printers
sudo systemctl restart cups

# Install additional drivers if needed
sudo rw
sudo apt-get install -y printer-driver-all
sudo apt-get install -y hplip  # For HP printers
sudo ro

# Manually add printer
lpadmin -p PrinterName -E -v usb://...
```

### Issue: Print Jobs Stuck in Queue

**Symptoms:**
- Jobs show as "Processing" but don't print
- Queue is frozen
- Printer shows as "Paused"

**Diagnosis:**

```bash
# Check print queue
lpstat -o

# Check printer status
lpstat -p

# Check CUPS error log
tail -f /var/log/cups/error_log
```

**Solutions:**

```bash
# Cancel all jobs
cancel -a

# Resume printer if paused
cupsenable PrinterName

# Restart CUPS
sudo systemctl restart cups

# Check printer connection
lpinfo -v

# Test with simple job
echo "Test" | lp -d PrinterName
```

### Issue: Web Configuration Interface Not Loading

**Symptoms:**
- Port 8080 not responding
- "Connection refused" error
- Blank page or error

**Diagnosis:**

```bash
# Check service status
systemctl status printalapy-web

# Check if port is open
sudo netstat -tulpn | grep 8080

# Check application logs
journalctl -u printalapy-web

# Test application manually
cd /opt/printalapy/webserver
python3 app.py
```

**Solutions:**

```bash
# Restart web service
sudo systemctl restart printalapy-web

# Check for Python errors
sudo journalctl -u printalapy-web -n 50

# Verify Flask is installed
python3 -c "import flask; print(flask.__version__)"

# Reinstall if needed
sudo rw
sudo pip3 install flask
sudo systemctl restart printalapy-web
sudo ro
```

### Issue: SNMP Not Responding

**Symptoms:**
- snmpwalk returns no data
- Connection timeout
- "No Such Object" errors

**Diagnosis:**

```bash
# Check SNMP service
systemctl status snmpd

# Check SNMP is listening
sudo netstat -tulpn | grep 161

# Test locally
snmpwalk -v2c -c public localhost system
```

**Solutions:**

```bash
# Restart SNMP service
sudo systemctl restart snmpd

# Check configuration
sudo rw
sudo cat /etc/snmp/snmpd.conf

# Reset configuration
sudo cp /etc/snmp/snmpd.conf.backup /etc/snmp/snmpd.conf
sudo bash /opt/printalapy/setup-snmp.sh
sudo systemctl restart snmpd
sudo ro

# Test with correct community string
snmpwalk -v2c -c public <pi-ip> system
```

### Issue: Cannot Write to Filesystem

**Symptoms:**
- "Read-only file system" error
- Cannot save files
- Configuration changes don't persist

**Diagnosis:**

```bash
# Check mount status
mount | grep " / "

# Check if overlayfs is active
mount | grep overlay
```

**Solutions:**

```bash
# Enable write mode temporarily
sudo rw

# Make your changes

# Return to read-only mode
sudo ro

# Disable overlayfs permanently (not recommended)
sudo rw
sudo nano /etc/overlayroot.conf
# Change overlayroot= to "disabled"
sudo reboot
```

### Issue: High CPU Usage

**Symptoms:**
- System slow to respond
- High load average
- Services timing out

**Diagnosis:**

```bash
# Check CPU usage
top
htop

# Check running processes
ps aux --sort=-%cpu | head -10

# Check system load
uptime
```

**Solutions:**

```bash
# Identify resource-hungry process
top

# Kill problematic process if needed
sudo kill <PID>

# Check for large print jobs
lpstat -o

# Cancel large jobs if needed
cancel <job-id>

# Reduce concurrent print jobs in CUPS
sudo rw
sudo nano /etc/cups/cupsd.conf
# Add: MaxJobs 3
sudo systemctl restart cups
sudo ro
```

### Issue: Network Performance Issues

**Symptoms:**
- Slow printing
- Timeouts
- Dropped connections

**Diagnosis:**

```bash
# Check network interface
ifconfig
ip addr show

# Test network speed
ping -c 10 <gateway>

# Check for errors
ifconfig | grep errors

# Monitor network traffic
sudo iftop
```

**Solutions:**

```bash
# Use wired connection instead of Wi-Fi
# Reduce print quality
# Update network drivers
sudo rw
sudo apt-get update
sudo apt-get upgrade -y
sudo ro

# Adjust network settings
sudo rw
sudo ethtool -s eth0 speed 100 duplex full
sudo ro
```

### Issue: SD Card Corruption

**Symptoms:**
- Random errors
- System becomes unstable
- Files appear corrupted
- Read/write errors in logs

**Diagnosis:**

```bash
# Check filesystem
sudo rw
sudo fsck -n /dev/mmcblk0p2

# Check for bad blocks
sudo badblocks -v /dev/mmcblk0

# Check disk usage
df -h

# Check for errors in logs
dmesg | grep -i "error\|fail"
```

**Solutions:**

```bash
# Backup important data immediately
sudo tar -czf /tmp/backup.tar.gz /etc/cups/ /opt/printalapy/config/

# Replace SD card
# Flash fresh image
# Restore configuration from backup

# Enable read-only filesystem (if not already)
sudo rw
sudo bash /opt/printalapy/setup-overlayfs.sh
sudo reboot
```

## Advanced Diagnostics

### Enable Debug Logging

**CUPS Debug Logging:**

```bash
sudo rw
sudo cupsctl --debug-logging
# Generate logs
sudo cupsctl --no-debug-logging
sudo ro
```

**System Debug Logging:**

```bash
# Increase systemd logging
sudo systemctl set-log-level debug

# Reset to normal
sudo systemctl set-log-level info
```

### Network Packet Capture

```bash
# Capture CUPS traffic
sudo tcpdump -i any port 631 -w cups-traffic.pcap

# Capture SNMP traffic
sudo tcpdump -i any port 161 -w snmp-traffic.pcap

# Analyze with Wireshark
```

### Performance Profiling

```bash
# Monitor system resources
sudo apt-get install sysstat
sar -u 1 10  # CPU usage
sar -r 1 10  # Memory usage
sar -b 1 10  # I/O usage

# Profile specific process
sudo perf record -p <PID>
sudo perf report
```

## Getting Help

If you cannot resolve the issue:

1. **Gather information:**
   ```bash
   # Create diagnostic report
   sudo /opt/printalapy/scripts/diagnostic-report.sh > diagnostic.txt
   ```

2. **Search existing issues:**
   - GitHub Issues: https://github.com/dezihh/PrintALaPi/issues

3. **Create a new issue:**
   - Include diagnostic information
   - Describe steps to reproduce
   - Include relevant logs
   - Mention your Pi model and OS version

4. **Community resources:**
   - CUPS Documentation: https://www.cups.org/documentation.html
   - Raspberry Pi Forums: https://forums.raspberrypi.com/

## Prevention Tips

### Regular Maintenance

```bash
# Weekly: Check system status
systemctl status cups snmpd

# Monthly: Update system
sudo rw
sudo apt-get update && sudo apt-get upgrade -y
sudo ro

# Quarterly: Backup configuration
sudo tar -czf backup-$(date +%Y%m%d).tar.gz /etc/cups/ /opt/printalapy/config/
```

### Best Practices

1. **Use quality SD card** - SanDisk or Samsung recommended
2. **Proper shutdown** - Always shutdown properly, don't just unplug
3. **Adequate power** - Use official Raspberry Pi power supply
4. **Regular backups** - Backup CUPS and PrintALaPi configuration
5. **Monitor logs** - Check logs periodically for warnings
6. **Keep updated** - Apply security updates regularly
7. **Read-only filesystem** - Keep enabled for reliability

### Monitoring Setup

Set up monitoring to catch issues early:

```bash
# Enable email notifications for errors (optional)
# Set up external SNMP monitoring
# Configure system health checks
# Set up automatic log rotation
```
