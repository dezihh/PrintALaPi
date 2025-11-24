echo "Bitte Script als Hauptuser ausführen!"
echo -n "Checke Systemzeit: "
date
echo 'Systemzeit korrekt? Sonst sudo date -s "11/23/25 11:38:00"'
echo -n 'Weiter? Abbruch mit Ctrl-C:'; read a

sudo apt update
sudo apt install -y cups avahi-daemon libnss-mdns printer-driver-all cups-bsd cups-client ipptool snmp snmp-mibs-downloader ntp
echo "Trage $USER als LpAdmin ein..."
sudo usermod -aG lpadmin $USER
sudo systemctl enable --now cups avahi-daemon



sudo wget https://github.com/dezihh/PrintALaPi/blob/master/scripts/cupsd.conf -c /etc/cups/cupsd.conf
