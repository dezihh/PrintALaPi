echo -n "Setze Systemzeit: "
date -s "$(curl -s --head http://google.com | grep ^Date: | sed 's/Date: //g')"

echo "Paketquellen aktualisieren und neue Pakete hinzufügen"
sudo apt update
sudo apt install -y cups avahi-daemon libnss-mdns printer-driver-all cups-bsd cups-client zram-tools sysstat lsof python3 python3-pip python3-flask
sudo apt-get purge colord

echo "Mache zram Einstellungen"
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
