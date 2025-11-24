echo "Bitte Script als Hauptuser ausführen!"
echo -n "Checke Systemzeit: "
date
echo 'Systemzeit korrekt? Sonst sudo date -s "11/23/25 11:38:00"'
echo -n 'Weiter? Abbruch mit Ctrl-C:'; read a

sudo apt update
sudo apt install -y cups avahi-daemon libnss-mdns printer-driver-all cups-bsd cups-client zram-tools
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
# tmpfs Mounts in fstab
cat >> /etc/fstab << 'FSTAB'

sudo tee /etc/systemd/system/zram-tmp.service >/dev/null << 'UNIT'
[Unit]
Description=ZRAM compressed filesystem for /tmp and CUPS
After=local-fs.target
Before=basic.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c '
  modprobe zram || true
  echo lz4 > /sys/block/zram1/comp_algorithm
  echo $((256*1024*1024)) > /sys/block/zram1/disksize
  mkfs.ext4 -q /dev/zram1
  mkdir -p /mnt/zram-tmp
  mount -t ext4 -o noatime,nosuid,nodev /dev/zram1 /mnt/zram-tmp

  # /tmp auf zram1
  mkdir -p /mnt/zram-tmp/tmp
  chmod 1777 /mnt/zram-tmp/tmp
  mount --bind /mnt/zram-tmp/tmp /tmp

  # CUPS Spool auf zram1
  mkdir -p /mnt/zram-tmp/cups
  chown lp:lp /mnt/zram-tmp/cups
  chmod 755 /mnt/zram-tmp/cups
  mount --bind /mnt/zram-tmp/cups /var/spool/cups
'

ExecStop=/bin/sh -c '
  umount /var/spool/cups || true
  umount /tmp || true
  umount /mnt/zram-tmp || true
  rmmod zram || true
'

[Install]
WantedBy=multi-user.target
UNIT

sudo tee /etc/systemd/system/zram-log.service >/dev/null << 'UNIT'
[Unit]
Description=ZRAM compressed filesystem for /var/log
After=local-fs.target
Before=basic.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c '
  modprobe zram || true
  echo lz4 > /sys/block/zram2/comp_algorithm
  echo $((64*1024*1024)) > /sys/block/zram2/disksize
  mkfs.ext4 -q /dev/zram2
  mkdir -p /mnt/zram-log
  mount -t ext4 -o noatime,nosuid,nodev /dev/zram2 /mnt/zram-log

  # Verzeichnisstruktur für /var/log anlegen (minimal)
  mkdir -p /mnt/zram-log/{cups,apt}
  mkdir -p /mnt/zram-log/journal
  chmod 755 /mnt/zram-log
  chown root:adm /mnt/zram-log
  mount --bind /mnt/zram-log /var/log
'

ExecStop=/bin/sh -c '
  umount /var/log || true
  umount /mnt/zram-log || true
'

[Install]
WantedBy=multi-user.target
UNIT


sudo systemctl enable zramswap
sudo systemctl enable zram-tmp.service
sudo systemctl enable zram-log.service

cat >> /etc/fstab << 'FSTAB'

# tmpfs für read-only System
# /run bleibt tmpfs (Standard), aber Größe begrenzen
tmpfs   /run            tmpfs   nosuid,noexec,nodev,mode=0755,size=32M           0 0
tmpfs   /run/lock       tmpfs   nosuid,nodev,size=4M                             0 0

# /tmp, /var/log, /var/spool/cups werden über systemd auf ZRAM gemountet/bound
# Platzhalter, damit systemd/Programme nicht meckern – noauto:
tmpfs   /tmp            tmpfs   defaults,noauto                                  0 0
tmpfs   /var/log        tmpfs   defaults,noauto                                  0 0
tmpfs   /var/spool/cups tmpfs   defaults,noauto 
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
