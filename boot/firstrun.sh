#!/usr/bin/env bash
set -euo pipefail

USER_NAME="printalapi"
USER_PASS_PLAIN="printalapi"
BOOT_AUTH_KEYS="/boot/firmware/authorized_keys"

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

echo -n "Setze Systemzeit: "
date -s "$(curl -s --head http://google.com | grep ^Date: | sed 's/Date: //g')"

echo "Paketquellen aktualisieren und neue Pakete hinzufügen"
sudo apt update
sudo apt install -y cups avahi-daemon libnss-mdns printer-driver-all cups-bsd cups-client zram-tools sysstat lsof python3 python3-pip python3-flask
sudo apt-get purge colord



