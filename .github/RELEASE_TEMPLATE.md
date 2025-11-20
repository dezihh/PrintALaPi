# PrintALaPi v1.0.0

🎉 **First Official Release of PrintALaPi!**

PrintALaPi transforms your Raspberry Pi into a powerful network print server with advanced features.

## 🚀 What's Included

This release includes a ready-to-use Raspberry Pi OS image with:

- **CUPS Print Server** - Full-featured print server supporting multiple printers
- **SNMP Monitoring** - Monitor printer status and system health
- **Captive Portal** - Easy Wi-Fi setup for initial configuration
- **Web Interface** - Simple configuration dashboard on port 8080
- **Read-Only Filesystem** - OverlayFS protection against power loss corruption
- **Automated Setup** - All services configured and ready to go

## 📥 Installation

### Quick Start

1. Download `printalapy.img.xz` from this release
2. Flash to an SD card (8GB minimum) using [Raspberry Pi Imager](https://www.raspberrypi.org/software/) or [balenaEtcher](https://www.balena.io/etcher/)
3. Insert SD card into your Raspberry Pi and power on
4. Connect to the "PrintALaPi-Setup" Wi-Fi network (password: `printalapy`)
5. Open browser to `http://192.168.4.1:8080`

### Detailed Instructions

See the [Installation Guide](https://github.com/dezihh/PrintALaPi/blob/main/INSTALL.md) for complete setup instructions.

## 🔧 Requirements

- Raspberry Pi (Model 2B or newer recommended)
- Micro SD card (8GB minimum, 16GB recommended)
- Power supply (5V 2.5A minimum)
- Optional: Wi-Fi adapter (built-in on Pi 3/4/Zero W)

## 📖 Documentation

- [README](https://github.com/dezihh/PrintALaPi/blob/main/README.md) - Project overview and features
- [Installation Guide](https://github.com/dezihh/PrintALaPi/blob/main/INSTALL.md) - Detailed setup instructions
- [Contributing Guidelines](https://github.com/dezihh/PrintALaPi/blob/main/CONTRIBUTING.md) - How to contribute

## 🆕 Features in v1.0.0

### Core Components
- CUPS print server with web-based administration
- SNMP monitoring for system and printer status
- Flask-based web dashboard for configuration
- Captive portal for easy network setup
- OverlayFS read-only filesystem protection

### Network Configuration
- Automatic DHCP configuration
- Wi-Fi access point mode (SSID: "PrintALaPi-Setup")
- Support for both Ethernet and Wi-Fi connectivity
- Static IP configuration support

### Administration
- CUPS web interface on port 631
- Configuration dashboard on port 8080
- Read-only filesystem with `rw`/`ro` commands
- Diagnostic reporting script
- Comprehensive logging

### Supported Printers
- USB printers
- Network printers (IPP, LPD, etc.)
- HP printers (with HPLIP support)

## 🔐 Default Credentials

- **Wi-Fi SSID**: PrintALaPi-Setup
- **Wi-Fi Password**: printalapy
- **CUPS Admin**: Use your Raspberry Pi system user credentials

⚠️ **Important**: Change default passwords after installation!

## 🐛 Known Issues

None at this time. Please [report any issues](https://github.com/dezihh/PrintALaPi/issues) you encounter.

## 🙏 Acknowledgments

- CUPS - Common UNIX Printing System
- Raspberry Pi Foundation
- Open-source community contributors

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/dezihh/PrintALaPi/blob/main/LICENSE) file for details.

## 💬 Support

For issues, questions, or suggestions:
- 📋 [Open an issue](https://github.com/dezihh/PrintALaPi/issues)
- 📖 Check the [documentation](https://github.com/dezihh/PrintALaPi/blob/main/INSTALL.md)
- 💡 Start a [discussion](https://github.com/dezihh/PrintALaPi/discussions)

---

**Full Changelog**: https://github.com/dezihh/PrintALaPi/blob/main/CHANGELOG.md
