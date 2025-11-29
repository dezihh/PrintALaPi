# PrintALaPi

PrintALaPi is a reproducible Raspberry Pi image configuration that uses cloud-init to bring a freshly-booted Pi into a defined state. It optionally provides a minimal CUPS print server install. The repository contains the cloud-init files (boot/user-data and boot/meta-data) and helper scripts.

## Quick overview

- After first boot you can log in with:
  - user: `printalapi`
  - password: `printalapi`
- The cloud-init configuration configures hostname, locale/timezone, keyboard, SSH, packages, and basic system settings.
- Two deployment paths:
  1. Run `/root/prepare.sh` (downloaded at first boot) to install a minimal print server. The print server will be reachable at `http://printalapi.local:631`.
  2. Do not run `/root/prepare.sh` and rely only on the cloud-init configuration from `/boot` for a standardized base installation.

## What cloud-init does (from boot/user-data)

Key actions performed during first boot:
- Set hostname to `PrintALaPi`, timezone `Europe/Berlin`, locale `de_DE.UTF-8`, and German keyboard layout (nodeadkeys).
- Enable password SSH auth and create user `printalapi` with sudo privileges.
- Set initial password `printalapi` and force password change on first login.
- Run boot commands to set the system clock (tries HTTP Date header fallback).
- Update and upgrade packages.
- Install packages including:
  - cups, avahi-daemon, libnss-mdns, printer-driver-all, cups-bsd, cups-client
  - zram-tools, sysstat, lsof
  - python3, python3-pip, python3-flask, git
- Write `/etc/modprobe.d/zram.conf` with `options zram num_devices=2`.
- Enable and start sshd.
- Download `https://raw.githubusercontent.com/dezihh/PrintALaPi/master/scripts/setup/start_prepare.sh` to `/root/prepare.sh` and mark it executable.
- Reboot when done.

Files in repo `/boot` you must copy to the SD card:
- `boot/meta-data` — sets instance-id and local-hostname.
- `boot/user-data` — the cloud-init configuration described above.

## Image creation / installation steps

1. Use Raspberry Pi Imager:
   - Select your Raspberry Pi model (1–5).
   - Choose OS → "Raspberry Pi OS (other)" → "Raspberry Pi OS Lite (32-bit)".
   - Flash the SD card.
2. After flashing, open the SD's FAT boot partition and copy these two files from this repo's `boot/` directory into the boot partition, overwriting any existing files:
   - `meta-data`
   - `user-data`
3. Insert the SD into the Pi and power it up. Cloud-init runs on first boot and will perform the configured tasks.
4. Log in locally or via SSH as `printalapi` / `printalapi`. Password is expired and must be changed at first login.
5. Optionally run:
   - `sudo /root/prepare.sh`
   This installs a minimal CUPS print server and related components. After completion the print server is reachable at `http://printalapi.local:631`.

Notes:
- No previous Pi settings are preserved — the configuration is fully driven by cloud-init files you copied to the boot partition.
- If you choose not to run `/root/prepare.sh`, the system will still be standardized per cloud-init (packages installed, ssh enabled, etc.) but no additional printserver setup will be made.

## Security & recommendations

- The out-of-the-box print server provided by `/root/prepare.sh` is minimal and intended for easy setup/demos. Harden CUPS and the system for production use:
  - Change the default password immediately.
  - Remove or replace any SSH keys you do not trust.
  - Configure CUPS access control, enable TLS, or restrict network access.
  - Consider adding a firewall (ufw/iptables) and disabling password auth for SSH once keys are configured.
- Review `scripts/setup/start_prepare.sh` before running it to understand exactly what it installs.

## Troubleshooting

- For minimizing IO to Flasj, there are no Files at /var/log!
- If `/root/prepare.sh` is missing, verify the Pi had network access on first boot and that the runcmd download succeeded.
- If hostname resolution to `printalapi.local` fails, ensure `avahi-daemon` is installed and running and that your network supports mDNS.

## Contributing

Contributions are welcome. If you change cloud-init behavior or the install scripts, please update this README and test a full flash → boot cycle.

## License

See repository license or add one as needed.
