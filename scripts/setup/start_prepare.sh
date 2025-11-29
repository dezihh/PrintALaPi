export USER=printalapi

sudo apt purge -y colord

sudo swapoff /dev/zram0
sudo systemctl stop zramswap
sudo systemctl disable zramswap
sudo rm -f /etc/default/zramswap
sudo modprobe -r zram

wget -O /usr/lib/systemd/system/zram-setup.service https://raw.githubusercontent.com/dezihh/PrintALaPi/master/scripts/zram-setup.service

sudo systemctl daemon-reload
sudo systemctl enable zram-setup.service
sudo systemctl start zram-setup.service
sudo loginctl disable-linger

# Stop rw services
sudo systemctl stop  man-db.timer   dpkg-db-backup.timer ModemManager polkit logrotate.timer logrotate.service
sudo systemctl disable man-db.timer   ModemManager polkit systemd-journald s logrotate.timer logrotate.service
sudo loginctl disable-linger
sudo systemctl mask user@1000.service
sudo usermod -aG lpadmin printalapi

# Stop Logs beeing writed
echo "[Journal]
Storage=none
SystemMaxUse=1M
ForwardToSyslog=no
ForwardToWall=no" >/etc/systemd/journald.conf

# Remove old Log stuff and link Directory to /dev/null
rm -rf /var/log
ln -s /dev/null /var/log

# Set our Cups config from github in place
sudo wget -O /etc/cups/cupsd.conf https://raw.githubusercontent.com/dezihh/PrintALaPi/master/scripts/cupsd.conf
sudo systemctl restart cups

# Some helpful information at logintime
sudo wget -O /etc/motd https://raw.githubusercontent.com/dezihh/PrintALaPi/master/scripts/motd

# No stay in homedir (important for RO Mode)
sudo echo "# Prevent starting D-Bus" >>/etc/profile




#sudo mkdir -p /var/spool/cups/cache
#sudo chown -R lp:lp /var/spool/cups
