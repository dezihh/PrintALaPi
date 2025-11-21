#!/bin/sh
# Setup-Script für Captive-Portal auf Raspberry Pi (read-only root berücksichtigt)
# Führt Installation, Datei-Erzeugung und Aktivierung der Dienste aus.
# Ausführen als root: sudo ./setup_captive_portal.sh

set -e

WLAN_IF="wlan0"
ETH_IF="eth0"
PING_TARGET="8.8.8.8"

# Hilfsfunktionen
log() { printf '%s %s\n' "$(date -Is)" "$*"; }
err() { log "ERROR: $*"; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || { err "Benötigt: $1"; exit 1; } }

if [ "$(id -u)" -ne 0 ]; then
  err "Bitte als root ausführen."
  exit 1
fi

# 1) Paketinstallation (apt-get; kann angepasst werden)
log "Installiere benötigte Pakete..."
if command -v apt-get >/dev/null 2>&1; then
  apt-get update
  apt-get install -y hostapd dnsmasq python3 python3-venv || {
    err "Paketinstallation schlug fehl (apt-get)."
  }
else
  log "Kein apt-get gefunden - bitte Pakete manuell installieren: hostapd, dnsmasq, python3"
fi

# 2) Erzeuge Server-Skript (nimmt SSID/PSK entgegen und persistiert sicher)
log "Schreibe /usr/local/bin/captive_portal.py"
cat > /usr/local/bin/captive_portal.py <<'PY'
#!/usr/bin/env python3
# Minimaler Captive-Portal-Server mit Formular zum Speichern von SSID/PSK.
import os, sys, subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs

HTML_FORM = b"""<html><head><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Captive Portal - WLAN konfigurieren</title></head><body style="font-family:sans-serif">
<h1>WLAN einrichten</h1>
<form method="POST">
SSID:<br><input name="ssid" required><br>
Passphrase (leer = offenes Netz):<br><input name="psk"><br><br>
<input type="submit" value="Speichern und verbinden">
</form>
</body></html>"""

CONF_OK = b"""<html><body><h1>Gespeichert</h1><p>Der Raspberry Pi versucht nun, sich mit dem eingegebenen Netzwerk zu verbinden.</p></body></html>"""

WPA_CONF_PATH = "/etc/wpa_supplicant/wpa_supplicant.conf"
BACKUP_SUFFIX = ".bak.captive"

def remount(root_mode):
    subprocess.run(["mount", "-o", f"remount,{root_mode}", "/"], check=True)

def atomic_write(path, data, mode=0o600):
    tmp = "/run/.tmp_wpa.conf"
    with open(tmp, "wb") as f:
        f.write(data)
    os.chmod(tmp, mode)
    # remount root rw, move file into place, sync, remount ro
    remount("rw")
    if os.path.exists(path):
        try:
            os.rename(path, path + BACKUP_SUFFIX)
        except Exception:
            pass
    os.replace(tmp, path)
    os.chmod(path, mode)
    subprocess.run(["sync"])
    remount("ro")

def make_wpa_conf(ssid, psk):
    ssid_quoted = '"' + ssid.replace('"','') + '"'
    if psk:
        psk_quoted = '"' + psk.replace('"','') + '"'
        net = f'\nnetwork={{\n    ssid={ssid_quoted}\n    psk={psk_quoted}\n}}\n'
    else:
        net = f'\nnetwork={{\n    ssid={ssid_quoted}\n    key_mgmt=NONE\n}}\n'
    header = 'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\nupdate_config=1\n'
    return (header + net).encode('utf-8')

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Simple responses for captive checks
        if self.path in ("/generate_204", "/favicon.ico"):
            self.send_response(200); self.end_headers(); return
        self.send_response(200)
        self.send_header("Content-Type","text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(HTML_FORM)))
        self.end_headers()
        self.wfile.write(HTML_FORM)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode('utf-8')
        form = parse_qs(body)
        ssid = form.get("ssid", [""])[0].strip()
        psk = form.get("psk", [""])[0].strip()
        if not ssid:
            self.send_response(400); self.end_headers(); return
        try:
            conf = make_wpa_conf(ssid, psk)
            atomic_write(WPA_CONF_PATH, conf)
            # trigger wpa_supplicant reload if possible
            subprocess.run(["wpa_cli", "-i", "wlan0", "reconfigure"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(["systemctl", "restart", "dhcpcd"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e:
            self.send_response(500); self.end_headers(); return
        self.send_response(200)
        self.send_header("Content-Type","text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(CONF_OK)))
        self.end_headers()
        self.wfile.write(CONF_OK)

    def log_message(self, fmt, *args):
        print("%s - - [%s] %s" % (self.client_address[0], self.log_date_time_string(), fmt%args))

def main():
    addr = ("0.0.0.0", 80)
    print("Starting captive portal server on :80")
    HTTPServer(addr, Handler).serve_forever()

if __name__ == "__main__":
    main()
PY
chmod +x /usr/local/bin/captive_portal.py

# 3) Manager-Skript (prüft Internet/Link/WLAN und startet/stopt AP-Stack)
log "Schreibe /usr/local/bin/captive-portal-manager.sh"
cat > /usr/local/bin/captive-portal-manager.sh <<'SH'
#!/bin/sh
WLAN="wlan0"
ETH="eth0"
PING_TARGET="8.8.8.8"
RUNDIR="/run/captive-portal"
ACTIVE_MARK="$RUNDIR/active"
mkdir -p "$RUNDIR"
log() { printf '%s %s\n' "$(date -Is)" "$*"; }

is_internet() {
  ping -c1 -W2 "$PING_TARGET" >/dev/null 2>&1
}
eth_carrier() {
  [ -f "/sys/class/net/$ETH/carrier" ] && grep -q 1 "/sys/class/net/$ETH/carrier"
}
wlan_connected() {
  command -v iw >/dev/null 2>&1 || return 1
  iw dev "$WLAN" link 2>/dev/null | grep -q "Connected to"
}
start_captive() {
  [ -f "$ACTIVE_MARK" ] && return 0
  log "Starting captive portal: configuring $WLAN ..."
  ip link set "$WLAN" down 2>/dev/null || true
  ip addr flush dev "$WLAN" 2>/dev/null || true
  ip addr add 192.168.50.1/24 dev "$WLAN" || true
  ip link set "$WLAN" up
  log "Starting hostapd, dnsmasq, captive server"
  systemctl start hostapd.service || log "hostapd start failed"
  systemctl start dnsmasq.service || log "dnsmasq start failed"
  systemctl start captive-portal-server.service || log "portal server start failed"
  touch "$ACTIVE_MARK"
}
stop_captive() {
  [ ! -f "$ACTIVE_MARK" ] && return 0
  log "Stopping captive portal"
  systemctl stop captive-portal-server.service || true
  systemctl stop dnsmasq.service || true
  systemctl stop hostapd.service || true
  ip addr flush dev "$WLAN" 2>/dev/null || true
  ip link set "$WLAN" down 2>/dev/null || true
  rm -f "$ACTIVE_MARK"
}
log "Captive portal manager started"
sleep 5
while true; do
  if is_internet; then
    log "Internet reachable -> ensure portal stopped"
    stop_captive
  else
    if eth_carrier; then
      log "Ethernet carrier detected -> ensure portal stopped"
      stop_captive
    else
      if wlan_connected; then
        log "WLAN connected -> ensure portal stopped"
        stop_captive
      else
        log "No WAN: starting captive portal"
        start_captive
      fi
    fi
  fi
  sleep 30
done
SH
chmod +x /usr/local/bin/captive-portal-manager.sh

# 4) hostapd config
log "Schreibe /etc/hostapd/hostapd.conf"
mkdir -p /etc/hostapd
cat > /etc/hostapd/hostapd.conf <<'HA'
interface=wlan0
driver=nl80211
ssid=RPi-Captive
hw_mode=g
channel=6
auth_algs=1
wmm_enabled=0
ignore_broadcast_ssid=0
HA

# 5) dnsmasq config
log "Schreibe /etc/dnsmasq.d/captive.conf"
mkdir -p /etc/dnsmasq.d
cat > /etc/dnsmasq.d/captive.conf <<'DN'
interface=wlan0
bind-interfaces
no-resolv
server=8.8.8.8
dhcp-range=192.168.50.10,192.168.50.50,12h
address=/#/192.168.50.1
log-queries
log-facility=/run/dnsmasq.captive.log
DN

# 6) systemd service: server
log "Schreibe /etc/systemd/system/captive-portal-server.service"
cat > /etc/systemd/system/captive-portal-server.service <<'SS'
[Unit]
Description=Captive Portal HTTP Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/captive_portal.py --host 0.0.0.0 --port 80
Restart=on-failure
RuntimeDirectory=captive-portal

[Install]
WantedBy=multi-user.target
SS

# 7) systemd service: manager
log "Schreibe /etc/systemd/system/captive-portal-manager.service"
cat > /etc/systemd/system/captive-portal-manager.service <<'MS'
[Unit]
Description=Captive Portal Manager (start AP when no WAN)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin
