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
sudo systemctl stop ModemManager
sudo systemctl disable ModemManager
sudo systemctl stop polkit
sudo systemctl disable polkit
# Stop rw services
sudo systemctl stop apt-daily.timer apt-daily-upgrade.timer man-db.timer e2scrub_all.timer fstrim.timer dpkg-db-backup.timer
sudo systemctl disable apt-daily.timer apt-daily-upgrade.timer man-db.timer e2scrub_all.timer fstrim.timer dpkg-db-backup.timer
echo "[Journal]
Storage=none
SystemMaxUse=1M
ForwardToSyslog=no
ForwardToWall=no" >/etc/systemd/journald.conf

sudo systemctl stop systemd-journald
sudo systemctl disable systemd-journald
sudo systemctl mask systemd-journald

rm -rf /var/log
ln -s /dev/null /var/log

#sudo systemctl stop NetworkManager
#sudo systemctl disable NetworkManager
#sudo systemctl mask NetworkManager

sudo systemctl stop systemd-timesyncd
sudo systemctl disable systemd-timesyncd

# 4. Logrotate deaktivieren (da wir keine Logs haben)
sudo systemctl stop logrotate.timer
sudo systemctl disable logrotate.timer
sudo systemctl stop logrotate.service
sudo systemctl disable logrotate.service


#echo "Trage $USER als LpAdmin ein..."
#sudo usermod -aG lpadmin $USER
#sudo systemctl enable --now cups avahi-daemon
#sudo wget -O /etc/cups/cupsd.conf "https://raw.githubusercontent.com/dezihh/PrintALaPi/master/scripts/cupsd.conf"
#sudo systemctl restart cups
# Drucker freigeben
#sudo lpadmin -p LexmarkE330 -o printer-is-shared=true
# AirPrint-kompatible MIME-Typen
#sudo lpadmin -p LexmarkE330 -o printer-op-policy=default

#sudo tee /usr/local/sbin/setup-zram-fs.sh >/dev/null << 'EOF'




#sudo mkdir -p /var/spool/cups/cache
#sudo chown -R lp:lp /var/spool/cups
