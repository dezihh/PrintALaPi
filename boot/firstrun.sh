#!/usr/bin/env bash
set -euo pipefail

LOG_FILE=/var/log/firstrun.log
STATE_FILE=/var/lib/firstrun.done

# nur einmal ausführen
if [ -f "$STATE_FILE" ]; then
  echo "firstrun.sh wurde bereits ausgeführt, beende."
  exit 0
fi

exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== firstrun.sh gestartet: $(date) ==="

USER_NAME="printalapi"
USER_PASS_PLAIN="printalapi"
BOOT_AUTH_KEYS="/boot/authorized_keys"

# 1) SSH aktivieren (Datei /boot/ssh anlegen)
if [ ! -f /boot/ssh ]; then
  touch /boot/ssh
  echo "SSH aktiviert (Datei /boot/ssh angelegt)."
else
  echo "SSH war bereits aktiviert."
fi

# 2) Lokalisierung / Tastatur auf de setzen
echo "Setze Locale und Tastatur auf de..."

# Locale
if command -v localectl &>/dev/null; then
  localectl set-locale LANG=de_DE.UTF-8
fi
sed -i 's/^# *de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen || true
locale-gen || true

# Tastatur (Konsole)
if command -v localectl &>/dev/null; then
  localectl set-keymap de
fi
if [ -f /etc/default/keyboard ]; then
  sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="de"/' /etc/default/keyboard || true
fi

# 3) Hostname setzen
TARGET_HOSTNAME="printalapi"
echo "$TARGET_HOSTNAME" > /etc/hostname
sed -i "s/^\(127\.0\.1\.1\).*$/\1 $TARGET_HOSTNAME/" /etc/hosts || \
  (echo "127.0.1.1       $TARGET_HOSTNAME" >> /etc/hosts)
echo "Hostname auf $TARGET_HOSTNAME gesetzt."

# 4) Benutzer printalapi anlegen (falls nicht vorhanden) + sudo
if id "$USER_NAME" &>/dev/null; then
  echo "Benutzer $USER_NAME existiert bereits."
else
  echo "Lege Benutzer $USER_NAME an..."
  useradd -m -s /bin/bash "$USER_NAME"
  echo "${USER_NAME}:${USER_PASS_PLAIN}" | chpasswd

  if getent group sudo &>/dev/null; then
    usermod -aG sudo "$USER_NAME"
    echo "Benutzer $USER_NAME zur Gruppe sudo hinzugefügt."
  else
    echo "Gruppe sudo existiert nicht, prüfe Gruppe wheel..."
    if getent group wheel &>/dev/null; then
      usermod -aG wheel "$USER_NAME"
      echo "Benutzer $USER_NAME zur Gruppe wheel hinzugefügt."
    fi
  fi
  echo "Benutzer $USER_NAME wurde angelegt."
fi

# 5) SSH-Keys importieren (root + printalapi)
if [ -f "$BOOT_AUTH_KEYS" ]; then
  echo "Importiere SSH-Keys aus $BOOT_AUTH_KEYS..."

  # root
  ROOT_SSH_DIR="/root/.ssh"
  ROOT_AUTH_KEYS="$ROOT_SSH_DIR/authorized_keys"
  mkdir -p "$ROOT_SSH_DIR"
  touch "$ROOT_AUTH_KEYS"
  cat "$BOOT_AUTH_KEYS" >> "$ROOT_AUTH_KEYS"
  chmod 700 "$ROOT_SSH_DIR"
  chmod 600 "$ROOT_AUTH_KEYS"
  chown -R root:root "$ROOT_SSH_DIR"
  echo "SSH-Keys für root aktualisiert."

  # printalapi
  USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
  USER_SSH_DIR="$USER_HOME/.ssh"
  USER_AUTH_KEYS="$USER_SSH_DIR/authorized_keys"
  mkdir -p "$USER_SSH_DIR"
  touch "$USER_AUTH_KEYS"
  cat "$BOOT_AUTH_KEYS" >> "$USER_AUTH_KEYS"
  chmod 700 "$USER_SSH_DIR"
  chmod 600 "$USER_AUTH_KEYS"
  chown -R "$USER_NAME":"$USER_NAME" "$USER_SSH_DIR"
  echo "SSH-Keys für $USER_NAME aktualisiert."

  # 6) Passwort-Login für printalapi deaktivieren
  echo "Deaktiviere Passwort-Login für $USER_NAME..."
  if ! grep -q "^Match User $USER_NAME" /etc/ssh/sshd_config; then
    cat <<EOF >> /etc/ssh/sshd_config

Match User $USER_NAME
    PasswordAuthentication no
EOF
    echo "SSH-Konfiguration für $USER_NAME ergänzt."
  fi

  systemctl restart ssh || systemctl restart sshd || true
  echo "SSH-Dienst neu gestartet."
else
  echo "Keine Datei $BOOT_AUTH_KEYS gefunden – überspringe SSH-Key-Import und Passwort-Deaktivierung."
fi


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

# 7) Markiere als erledigt
mkdir -p "$(dirname "$STATE_FILE")"
touch "$STATE_FILE"
echo "firstrun.sh als erledigt markiert: $STATE_FILE"

echo "=== firstrun.sh abgeschlossen: $(date) ==="
