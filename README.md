# PrintALaPi 🖨️

Give your retired Raspberry Pi new life as a powerful print server!

PrintALaPi transforms a standard Raspberry Pi with Raspbian OS into a fully-featured network print server with advanced features like SNMP monitoring, captive portal setup, web-based configuration, and a read-only filesystem for enhanced reliability.

## Features

- **🖨️ CUPS Print Server** - Full-featured print server supporting multiple printers
- **📊 SNMP Monitoring** - Monitor printer status and system health via SNMP
- **📡 Captive Portal** - Easy Wi-Fi setup for initial configuration
- **🌐 Web Interface** - Simple web-based configuration dashboard
- **🔒 Read-Only Filesystem** - OverlayFS protection against power loss corruption
- **🚀 Automated Build** - GitHub Actions workflow to create ready-to-use images

## Quick Start

### Option 1: Download Pre-built Image (Coming Soon)

1. Download the latest PrintALaPi image from the [Releases](https://github.com/dezihh/PrintALaPi/releases) page
2. Flash the image to an SD card using [Raspberry Pi Imager](https://www.raspberrypi.org/software/) or [balenaEtcher](https://www.balena.io/etcher/)
3. Insert the SD card into your Raspberry Pi and power it on
4. Connect to the "PrintALaPi-Setup" Wi-Fi network (password: `printalapy`)
5. Open a browser and navigate to `http://192.168.4.1:8080`

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/dezihh/PrintALaPi.git
cd PrintALaPi

# Run the build script (requires Linux with loop device support)
cd build
sudo ./customize-image.sh
```

## Configuration

### Initial Setup

On first boot, the system will automatically:
1. Install and configure CUPS print server
2. Set up SNMP monitoring
3. Configure the captive portal (if Wi-Fi is available)
4. Start the web configuration interface
5. Enable read-only filesystem protection
6. Reboot to apply all changes

### Accessing Services

- **Web Configuration**: `http://<pi-ip>:8080`
- **CUPS Interface**: `http://<pi-ip>:631`
- **SNMP**: Port 161 (UDP)

### Default Credentials

- **Wi-Fi SSID**: PrintALaPi-Setup
- **Wi-Fi Password**: printalapy
- **CUPS Admin**: Use your system user (default: `pi`)

## Architecture

### Components

1. **CUPS** - Common UNIX Printing System
   - Handles print job management
   - Provides network printing protocols (IPP, LPD)
   - Web-based printer administration

2. **SNMP** - Simple Network Management Protocol
   - Monitors printer status
   - Provides system health information
   - Enables remote monitoring

3. **Captive Portal** - Network Setup Assistant
   - **hostapd** - Creates Wi-Fi access point
   - **dnsmasq** - Provides DHCP and DNS services
   - Simplifies initial network configuration

4. **Web Server** - Configuration Dashboard
   - Flask-based Python application
   - System status monitoring
   - Basic configuration management

5. **OverlayFS** - Read-Only Filesystem
   - Protects root filesystem from corruption
   - Allows temporary writes to RAM
   - Prevents SD card damage from power loss

## File Structure

```
PrintALaPi/
├── .github/
│   └── workflows/
│       └── build-image.yml       # GitHub Actions build workflow
├── build/
│   └── customize-image.sh        # Image customization script
├── scripts/
│   ├── setup.sh                  # Main setup script
│   ├── setup-cups.sh             # CUPS configuration
│   ├── setup-snmp.sh             # SNMP configuration
│   ├── setup-portal.sh           # Captive portal setup
│   ├── setup-webserver.sh        # Web server setup
│   └── setup-overlayfs.sh        # Read-only filesystem setup
├── config/
│   └── printalapy.conf           # Configuration file
├── webserver/
│   └── app.py                    # Flask web application
└── README.md
```

## Customization

Edit `/opt/printalapy/config/printalapy.conf` on the Raspberry Pi to customize settings such as:
- Wi-Fi SSID and password
- IP address ranges
- SNMP community strings
- Feature enablement flags

## Maintenance

### Enabling Write Access

The root filesystem is read-only by default. To make changes:

```bash
# Enable write access
sudo rw

# Make your changes...

# Return to read-only mode
sudo ro
```

### Adding Printers

1. Access CUPS web interface: `http://<pi-ip>:631`
2. Go to Administration → Add Printer
3. Follow the wizard to add your printer
4. Configure printer settings as needed

### Monitoring with SNMP

```bash
# Query system information
snmpwalk -v2c -c public <pi-ip> system

# Check printer status
snmpwalk -v2c -c public <pi-ip> NET-SNMP-EXTEND-MIB::nsExtendOutput1Line
```

## Troubleshooting

### Cannot connect to Wi-Fi

- Ensure the Raspberry Pi has a wireless adapter
- Check that hostapd service is running: `systemctl status hostapd`
- Verify network interface in `/etc/hostapd/hostapd.conf`

### CUPS not accessible

- Check CUPS service: `systemctl status cups`
- Verify firewall settings
- Ensure you're connecting to the correct IP address

### Printers not detected

- Verify printer is connected via USB or network
- Check printer drivers are installed
- Review CUPS error logs: `/var/log/cups/error_log`

## Requirements

- Raspberry Pi (Model 2B or newer recommended)
- Micro SD card (8GB minimum, 16GB recommended)
- Raspbian OS Lite (Bookworm or newer)
- Wi-Fi adapter (for captive portal feature)
- Network connection (Ethernet or Wi-Fi)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- CUPS - Common UNIX Printing System
- Raspberry Pi Foundation
- Open-source community

## Support

For issues, questions, or suggestions, please [open an issue](https://github.com/dezihh/PrintALaPi/issues) on GitHub
