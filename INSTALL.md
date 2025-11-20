# Installation Guide

This guide provides detailed instructions for installing and configuring PrintALaPi.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
- [Post-Installation Configuration](#post-installation-configuration)
- [Network Setup](#network-setup)
- [Adding Printers](#adding-printers)

## Prerequisites

### Hardware Requirements

- Raspberry Pi (Model 2B, 3, 4, or Zero W/WH)
- Micro SD card (8GB minimum, 16GB+ recommended)
- Power supply (5V 2.5A minimum)
- USB printer or network printer
- Optional: Wi-Fi adapter (built-in on Pi 3/4/Zero W)

### Software Requirements

- Raspberry Pi Imager or balenaEtcher
- Computer with SD card reader
- Network connection (Ethernet or Wi-Fi)

## Installation Methods

### Method 1: Pre-built Image (Recommended)

1. **Download the Image**
   ```bash
   # Download from releases page
   wget https://github.com/dezihh/PrintALaPi/releases/latest/download/printalapy.img.xz
   ```

2. **Flash to SD Card**
   - Using Raspberry Pi Imager:
     - Select "Use custom" image
     - Choose the downloaded printalapy.img.xz file
     - Select your SD card
     - Click "Write"
   
   - Using balenaEtcher:
     - Click "Flash from file"
     - Select the printalapy.img.xz file
     - Select your SD card
     - Click "Flash!"

3. **Boot the Raspberry Pi**
   - Insert the SD card into your Raspberry Pi
   - Connect Ethernet cable (optional)
   - Connect power supply
   - Wait 5-10 minutes for initial setup

### Method 2: Manual Installation

1. **Flash Raspberry Pi OS Lite**
   - Download [Raspberry Pi OS Lite](https://www.raspberrypi.org/software/operating-systems/)
   - Flash to SD card using Raspberry Pi Imager
   - Enable SSH (create empty file named `ssh` in boot partition)

2. **Boot and Update**
   ```bash
   sudo apt-get update
   sudo apt-get upgrade -y
   ```

3. **Clone Repository**
   ```bash
   cd /opt
   sudo git clone https://github.com/dezihh/PrintALaPi.git printalapy
   cd printalapy
   ```

4. **Run Installation**
   ```bash
   sudo bash scripts/setup.sh
   ```

## Post-Installation Configuration

### First Boot Setup

1. **Connect to Wi-Fi Access Point**
   - SSID: `PrintALaPi-Setup`
   - Password: `printalapy`

2. **Access Web Interface**
   - Open browser to: `http://192.168.4.1:8080`
   - Review system status
   - Note the IP addresses

3. **Configure Network (Optional)**
   - If using Ethernet, the Pi will get an IP via DHCP
   - Connect to that IP instead: `http://<ethernet-ip>:8080`

### Accessing CUPS

1. Open browser to: `http://<pi-ip>:631`
2. Click "Administration"
3. Log in with system credentials (default: `pi` / your password)

## Network Setup

### Ethernet Connection

The Raspberry Pi will automatically get an IP address via DHCP.

To find the IP:
```bash
# On the Pi
hostname -I

# From another computer
nmap -sn 192.168.1.0/24  # Adjust subnet as needed
```

### Wi-Fi Client Mode

To connect the Pi to an existing Wi-Fi network:

1. Enable write mode:
   ```bash
   sudo rw
   ```

2. Configure Wi-Fi:
   ```bash
   sudo raspi-config
   # Select: System Options → Wireless LAN
   # Enter SSID and password
   ```

3. Return to read-only mode:
   ```bash
   sudo ro
   ```

### Static IP Configuration

1. Enable write mode: `sudo rw`

2. Edit network configuration:
   ```bash
   sudo nano /etc/dhcpcd.conf
   ```

3. Add static IP configuration:
   ```
   interface eth0
   static ip_address=192.168.1.100/24
   static routers=192.168.1.1
   static domain_name_servers=192.168.1.1 8.8.8.8
   ```

4. Reboot: `sudo reboot`

## Adding Printers

### USB Printer

1. Connect printer to Raspberry Pi USB port
2. Access CUPS: `http://<pi-ip>:631`
3. Administration → Add Printer
4. Select your USB printer
5. Choose driver and configure

### Network Printer

1. Access CUPS: `http://<pi-ip>:631`
2. Administration → Add Printer
3. Select network protocol (IPP, LPD, etc.)
4. Enter printer address: `ipp://printer-ip/ipp/print`
5. Configure driver and settings

### HP Printers

For HP printers, install HPLIP:

```bash
sudo rw
sudo apt-get install -y hplip
sudo hp-setup -i
sudo ro
```

## Monitoring

### SNMP Monitoring

Query printer status:
```bash
snmpwalk -v2c -c public <pi-ip> NET-SNMP-EXTEND-MIB::nsExtendOutput1Line
```

### System Status

Check service status:
```bash
systemctl status cups
systemctl status snmpd
systemctl status hostapd
systemctl status printalapy-web
```

View logs:
```bash
sudo journalctl -u cups
sudo journalctl -u printalapy-web
tail -f /var/log/cups/error_log
```

## Troubleshooting

### Issue: Cannot access CUPS web interface

**Solution:**
```bash
# Check CUPS status
systemctl status cups

# Restart CUPS
sudo systemctl restart cups

# Check firewall
sudo iptables -L
```

### Issue: Printer not detected

**Solution:**
```bash
# List USB devices
lsusb

# Check for printer
lpinfo -v

# Check CUPS log
tail -f /var/log/cups/error_log
```

### Issue: Cannot write to filesystem

**Solution:**
```bash
# The filesystem is read-only by default
sudo rw  # Enable write mode

# Make your changes

sudo ro  # Return to read-only mode
```

### Issue: Wi-Fi access point not working

**Solution:**
```bash
# Check hostapd status
systemctl status hostapd

# Check wireless interface
iwconfig

# Restart hostapd
sudo systemctl restart hostapd
```

## Advanced Configuration

### Custom Configuration

Edit configuration file:
```bash
sudo rw
sudo nano /opt/printalapy/config/printalapy.conf
```

### Disable Read-Only Filesystem

If you need permanent write access:

```bash
sudo rw
sudo nano /etc/overlayroot.conf
# Change: overlayroot="tmpfs:swap=1,recurse=0"
# To: overlayroot="disabled"
sudo reboot
```

### Custom CUPS Configuration

```bash
sudo rw
sudo nano /etc/cups/cupsd.conf
sudo systemctl restart cups
sudo ro
```

## Security Considerations

1. **Change Default Passwords**
   ```bash
   sudo rw
   passwd  # Change user password
   sudo ro
   ```

2. **Firewall Configuration**
   ```bash
   sudo rw
   sudo apt-get install -y ufw
   sudo ufw allow 631/tcp  # CUPS
   sudo ufw allow 8080/tcp # Web interface
   sudo ufw allow 161/udp  # SNMP
   sudo ufw enable
   sudo ro
   ```

3. **Update System**
   ```bash
   sudo rw
   sudo apt-get update
   sudo apt-get upgrade -y
   sudo ro
   ```

## Support

For additional help:
- GitHub Issues: https://github.com/dezihh/PrintALaPi/issues
- CUPS Documentation: https://www.cups.org/documentation.html
- Raspberry Pi Forums: https://forums.raspberrypi.com/
