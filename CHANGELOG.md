# Changelog

All notable changes to PrintALaPi will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2025-11-20

### Fixed
- Fixed GitHub Actions workflow to properly invoke customize-image.sh with required image path argument
- Added release creation capability when version tags are pushed

## [1.0.0] - 2025-11-20

### Added
- Initial release of PrintALaPi - Raspberry Pi Print Server
- CUPS print server integration for managing network printers
- SNMP monitoring for printer status and system health
- Captive portal for easy Wi-Fi configuration on first boot
- Web-based configuration dashboard (Flask application)
- Read-only filesystem protection using OverlayFS
- Automated image build process via GitHub Actions
- Comprehensive documentation (README, INSTALL, CONTRIBUTING)
- Setup scripts for automated installation:
  - Main setup script
  - CUPS configuration
  - SNMP setup
  - Captive portal setup
  - Web server setup
  - OverlayFS configuration
- Configuration file for customizing settings
- Diagnostic reporting script

### Features
- Support for USB and network printers
- Network printing protocols (IPP, LPD)
- Web interface for system monitoring and configuration
- SNMP-based remote monitoring
- Automatic DHCP configuration
- Wi-Fi access point mode for initial setup
- Protection against SD card corruption from power loss
- Easy printer administration via CUPS web interface

### Documentation
- Detailed README with quick start guide
- Installation guide with multiple installation methods
- Contributing guidelines
- MIT License

[Unreleased]: https://github.com/dezihh/PrintALaPi/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/dezihh/PrintALaPi/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/dezihh/PrintALaPi/releases/tag/v1.0.0
