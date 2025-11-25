echo "Bitte Script als Hauptuser ausführen!"
echo -n "Setze Systemzeit: "
date -s "$(curl -s --head http://google.com | grep ^Date: | sed 's/Date: //g')"
date
echo 'Systemzeit korrekt? Sonst sudo date -s "11/23/25 11:38:00"'
echo -n 'Weiter? Abbruch mit Ctrl-C:'; read a

sudo apt update
sudo apt install -y cups avahi-daemon libnss-mdns printer-driver-all cups-bsd cups-client zram-tools sysstat lsof python3 python3-pip python3-flask
sudo apt-get purge colord

echo "Trage $USER als LpAdmin ein..."
sudo usermod -aG lpadmin $USER
sudo systemctl enable --now cups avahi-daemon
sudo wget -O /etc/cups/cupsd.conf "https://raw.githubusercontent.com/dezihh/PrintALaPi/master/scripts/cupsd.conf"
sudo systemctl restart cups
# Drucker freigeben
sudo lpadmin -p LexmarkE330 -o printer-is-shared=true
# AirPrint-kompatible MIME-Typen
sudo lpadmin -p LexmarkE330 -o printer-op-policy=default

cat > /etc/default/zramswap << 'ZRAM'
ALGO=lz4
PERCENT=25
PRIORITY=100
ZRAM

# Mehrere zram interface erstellen
sudo tee /etc/modprobe.d/zram.conf >/dev/null << 'CONF'
options zram num_devices=3
CONF

sudo tee /etc/modules-load.d/zram.conf >/dev/null << 'CONF'
zram
CONF

sudo tee /usr/local/sbin/setup-zram-fs.sh >/dev/null << 'EOF'
#!/bin/sh
# setup-zram-fs.sh <devnum> <size_bytes> <mountpoint> <bind_target_or_dash> <mode> <owner:group>

set -e

DEVNUM="$1"
SIZE="$2"
MOUNTPOINT="$3"
BINDTARGET="$4"
MODE="$5"
OWNER="$6"

if [ -z "$DEVNUM" ] || [ -z "$SIZE" ] || [ -z "$MOUNTPOINT" ]; then
  echo "Usage: $0 <devnum> <size_bytes> <mountpoint> <bind_target_or_dash> <mode> <owner:group>" >&2
  exit 1
fi

DEVPATH="/dev/zram${DEVNUM}"

if [ ! -e "$DEVPATH" ]; then
  echo "Device $DEVPATH does not exist" >&2
  exit 1
fi

# Wenn bereits benutzt (Swap/FS), nicht überschreiben
if grep -q "$DEVPATH" /proc/swaps || mount | grep -q "on $MOUNTPOINT "; then
  exit 0
fi

echo lz4 > "/sys/block/zram${DEVNUM}/comp_algorithm"
echo "$SIZE" > "/sys/block/zram${DEVNUM}/disksize"

mkfs.ext4 -q "$DEVPATH"

mkdir -p "$MOUNTPOINT"
mount -t ext4 -o noatime,nosuid,nodev "$DEVPATH" "$MOUNTPOINT"

# Rechte/Owner
[ -n "$MODE" ] && chmod "$MODE" "$MOUNTPOINT" || true
[ -n "$OWNER" ] && chown "$OWNER" "$MOUNTPOINT" || true

# Optionaler Bind-Mount
if [ "$BINDTARGET" != "-" ]; then
  mkdir -p "$BINDTARGET"
  mount --bind "$MOUNTPOINT" "$BINDTARGET"
fi

exit 0
EOF

sudo chmod +x /usr/local/sbin/setup-zram-fs.sh

sudo tee /usr/local/sbin/setup-zram-tmp-cups.sh >/dev/null << 'EOF'
#!/bin/sh
set -e

# /mnt/zram-tmp ist bereits von setup-zram-fs.sh gemountet

# /tmp
mkdir -p /mnt/zram-tmp/tmp
chmod 1777 /mnt/zram-tmp/tmp
mount --bind /mnt/zram-tmp/tmp /tmp

# CUPS Spool
mkdir -p /mnt/zram-tmp/cups/cache
chown -R lp:lp /mnt/zram-tmp/cups
chmod 755 /mnt/zram-tmp/cups
mount --bind /mnt/zram-tmp/cups /var/spool/cups

exit 0
EOF

sudo chmod +x /usr/local/sbin/setup-zram-tmp-cups.sh

sudo tee /etc/systemd/system/zram-log.service >/dev/null << 'UNIT'
[Unit]
Description=ZRAM compressed filesystem for /var/log
After=local-fs.target
Before=basic.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/setup-zram-fs.sh 2 67108864 /mnt/zram-log /var/log 755 root:adm

[Install]
WantedBy=multi-user.target
UNIT

sudo tee /etc/systemd/system/zram-tmp.service >/dev/null << 'UNIT'
[Unit]
Description=ZRAM compressed filesystem for /tmp and CUPS
After=local-fs.target
Before=basic.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/setup-zram-fs.sh 1 268435456 /mnt/zram-tmp - 755 root:root
ExecStart=/usr/local/sbin/setup-zram-tmp-cups.sh

ExecStop=/bin/sh -c 'umount /var/spool/cups || true; umount /tmp || true; umount /mnt/zram-tmp || true'

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable zramswap
sudo systemctl enable zram-tmp.service
sudo systemctl enable zram-log.service
sudo systemctl enable zram-log.service zram-tmp.service
sudo systemctl start zram-log.service
sudo systemctl start zram-tmp.service

reboot

-----------------------------------------
sudo tee /usr/local/sbin/setup-zram-fs.sh >/dev/null << 'EOF'
#!/bin/sh
# setup-zram-fs.sh <devnum> <size_bytes> <mountpoint> <bind_target_or_dash> <mode> <owner:group>

set -e

DEVNUM="$1"
SIZE="$2"
MOUNTPOINT="$3"
BINDTARGET="$4"
MODE="$5"
OWNER="$6"

if [ -z "$DEVNUM" ] || [ -z "$SIZE" ] || [ -z "$MOUNTPOINT" ]; then
  echo "Usage: $0 <devnum> <size_bytes> <mountpoint> <bind_target_or_dash> <mode> <owner:group>" >&2
  exit 1
fi

DEVPATH="/dev/zram${DEVNUM}"

if [ ! -e "$DEVPATH" ]; then
  echo "Device $DEVPATH does not exist" >&2
  exit 1
fi

# Wenn Device schon als Swap läuft, nicht anfassen
if grep -q "$DEVPATH" /proc/swaps; then
  echo "$DEVPATH is swap, skipping" >&2
  exit 0
fi

# Wenn Mountpoint schon gemountet ist, nichts tun
if mount | grep -q "on $MOUNTPOINT "; then
  exit 0
fi

echo lz4 > "/sys/block/zram${DEVNUM}/comp_algorithm"
echo "$SIZE" > "/sys/block/zram${DEVNUM}/disksize"

mkfs.ext4 -q "$DEVPATH"

mkdir -p "$MOUNTPOINT"
mount -t ext4 -o noatime,nosuid,nodev "$DEVPATH" "$MOUNTPOINT"

# Rechte/Owner
[ -n "$MODE" ] && chmod "$MODE" "$MOUNTPOINT" || true
[ -n "$OWNER" ] && chown "$OWNER" "$MOUNTPOINT" || true

# Optionaler Bind-Mount
if [ "$BINDTARGET" != "-" ]; then
  mkdir -p "$BINDTARGET"
  mount --bind "$MOUNTPOINT" "$BINDTARGET"
fi

exit 0
EOF

sudo chmod +x /usr/local/sbin/setup-zram-fs.sh

sudo tee /usr/local/sbin/setup-zram-tmp-cups.sh >/dev/null << 'EOF'
#!/bin/sh
set -e

# /mnt/zram-tmp ist bereits von setup-zram-fs.sh gemountet

# /tmp
mkdir -p /mnt/zram-tmp/tmp
chmod 1777 /mnt/zram-tmp/tmp
mount --bind /mnt/zram-tmp/tmp /tmp

# CUPS Spool
mkdir -p /mnt/zram-tmp/cups/cache
chown -R lp:lp /mnt/zram-tmp/cups
chmod 755 /mnt/zram-tmp/cups
mount --bind /mnt/zram-tmp/cups /var/spool/cups

exit 0
EOF

sudo chmod +x /usr/local/sbin/setup-zram-tmp-cups.sh

sudo tee /etc/systemd/system/zram-log.service >/dev/null << 'UNIT'
[Unit]
Description=ZRAM compressed filesystem for /var/log
After=local-fs.target
Before=basic.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/setup-zram-fs.sh 2 67108864 /mnt/zram-log /var/log 755 root:adm

[Install]
WantedBy=multi-user.target
UNIT

sudo tee /etc/systemd/system/zram-tmp.service >/dev/null << 'UNIT'
[Unit]
Description=ZRAM compressed filesystem for /tmp and CUPS
After=local-fs.target
Before=basic.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/setup-zram-fs.sh 1 268435456 /mnt/zram-tmp - 755 root:root
ExecStart=/usr/local/sbin/setup-zram-tmp-cups.sh

ExecStop=/bin/sh -c 'umount /var/spool/cups || true; umount /tmp || true; umount /mnt/zram-tmp || true'

[Install]
WantedBy=multi-user.target
UNIT




cat >> /etc/fstab << 'FSTAB'

# tmpfs für read-only System
# /run bleibt tmpfs (Standard), aber Größe begrenzen
tmpfs   /run            tmpfs   nosuid,noexec,nodev,mode=0755,size=32M           0 0
tmpfs   /run/lock       tmpfs   nosuid,nodev,size=4M                             0 0

FSTAB

sudo tee /etc/systemd/journald.conf >/dev/null << 'JOURNAL'
[Journal]
Storage=volatile
RuntimeMaxUse=8M
SystemMaxUse=8M
MaxRetentionSec=1day
JOURNAL

sudo systemctl restart systemd-journald

sudo systemctl disable --now rsyslog
sudo systemctl disable --now syslog-ng

#sudo sed -i 's#^RequestRoot .*#RequestRoot /var/spool/cups#g' /etc/cups/cupsd.conf || true
#sudo sed -i 's#^CacheDir .*#CacheDir /var/spool/cups/cache#g' /etc/cups/cupsd.conf || true

sudo mkdir -p /var/spool/cups/cache
sudo chown -R lp:lp /var/spool/cups
