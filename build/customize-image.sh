 url=https://github.com/dezihh/PrintALaPi/blob/master/build/customize-image.sh
#!/usr/bin/env bash
set -euo pipefail
# Anpassung: erkennt .xz/.gz/.zip und dekomprimiert automatisch, danach setzt IMG auf die .img-Datei

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <image-archive-or-img>"
  exit 1
fi

ARCHIVE="$1"
WORKDIR="$(pwd)"
TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

# Ensure necessary tools
if ! command -v file >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y file; fi
if ! command -v xz >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y xz-utils; fi
if ! command -v unzip >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y unzip; fi
if ! command -v kpartx >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y kpartx; fi

echo "Input: $ARCHIVE"
if [ ! -f "$ARCHIVE" ]; then
  echo "Datei $ARCHIVE nicht gefunden."
  exit 2
fi

MIME=$(file --brief --mime-type "$ARCHIVE")
case "$MIME" in
  application/x-xz|application/x-xz-compressed|application/x-compressed)
    echo "Detected xz compressed archive, decompressing..."
    cp "$ARCHIVE" "$TMPDIR/"
    BASENAME="$(basename "$ARCHIVE")"
    (cd "$TMPDIR" && xz -d -k "$BASENAME")
    IMG_CANDIDATE="$(find "$TMPDIR" -type f -name '*.img' -print -quit)"
    ;;
  application/gzip)
    echo "Detected gzip compressed archive, decompressing..."
    cp "$ARCHIVE" "$TMPDIR/"
    BASENAME="$(basename "$ARCHIVE")"
    (cd "$TMPDIR" && gunzip -k "$BASENAME")
    IMG_CANDIDATE="$(find "$TMPDIR" -type f -name '*.img' -print -quit)"
    ;;
  application/zip)
    echo "Detected zip archive, extracting..."
    unzip -d "$TMPDIR" "$ARCHIVE"
    IMG_CANDIDATE="$(find "$TMPDIR" -type f -name '*.img' -print -quit)"
    ;;
  application/octet-stream|inode/x-empty)
    # could already be an .img
    if [[ "$ARCHIVE" =~ \.img$ ]]; then
      IMG_CANDIDATE="$(realpath "$ARCHIVE")"
    else
      echo "Unbekanntes Format, versuche .img zu finden..."
      IMG_CANDIDATE="$(find "$WORKDIR" -maxdepth 1 -type f -name '*.img' -print -quit)"
    fi
    ;;
  *)
    # fallback: if ends with .xz/.img.gz/.zip
    case "$ARCHIVE" in
      *.xz) xz -d -k "$ARCHIVE"; IMG_CANDIDATE="${ARCHIVE%.xz}";;
      *.gz) gunzip -k "$ARCHIVE"; IMG_CANDIDATE="${ARCHIVE%.gz}";;
      *.zip) unzip -d "$TMPDIR" "$ARCHIVE"; IMG_CANDIDATE="$(find "$TMPDIR" -type f -name '*.img' -print -quit)";;
      *.img) IMG_CANDIDATE="$(realpath "$ARCHIVE")";;
      *) echo "Unbekanntes Archivformat: $ARCHIVE"; exit 3;;
    esac
    ;;
esac

if [ -z "${IMG_CANDIDATE:-}" ] || [ ! -f "$IMG_CANDIDATE" ]; then
  echo "Keine .img Datei gefunden nach Dekompression."
  exit 4
fi

IMG="$(realpath "$IMG_CANDIDATE")"
echo "Using image: $IMG"

# Beispiel: mounten und Repo kopieren (wie in README vorgesehen)
LOOPDEV="$(sudo losetup --show -fP "$IMG")"
echo "Loop device: $LOOPDEV"

# Partition devices (p1 boot, p2 root) - kpartx alternative if needed
BOOT="${LOOPDEV}p1"
ROOT="${LOOPDEV}p2"
# Falls Kernel nicht pN unterstützt, fallback zu kpartx
if [ ! -b "$BOOT" ] || [ ! -b "$ROOT" ]; then
  echo "Kernel-loop partition device nicht vorhanden, verwende kpartx."
  sudo kpartx -av "$IMG"
  MAPPREFIX="$(basename "$LOOPDEV")"
  # find mapping like /dev/mapper/loop0p1
  BOOT="$(ls /dev/mapper | grep "${MAPPREFIX}p1" | head -n1)"
  ROOT="$(ls /dev/mapper | grep "${MAPPREFIX}p2" | head -n1)"
  BOOT="/dev/mapper/$BOOT"
  ROOT="/dev/mapper/$ROOT"
fi

sudo mkdir -p /mnt/rpi_boot /mnt/rpi_root
sudo mount "$BOOT" /mnt/rpi_boot
sudo mount "$ROOT" /mnt/rpi_root

# Kopiere Repo ins Image
echo "Kopiere Repo nach /opt/printalapy im Image..."
sudo rsync -a --delete "$WORKDIR/../PrintALaPi/" /mnt/rpi_root/opt/printalapy/

# qemu für chroot einrichten
if [ -x /usr/bin/qemu-arm-static ]; then
  sudo cp /usr/bin/qemu-arm-static /mnt/rpi_root/usr/bin/ || true
fi

for fs in dev proc sys run; do sudo mount --bind /$fs /mnt/rpi_root/$fs || true; done

# chroot und ausführen (non-interactive)
echo "Starte chroot und führe build scripts aus..."
sudo chroot /mnt/rpi_root /bin/bash -lc "cd /opt/printalapy/build && ./customize-image.sh || true"

echo "Fertig. Unmounten..."
for fs in run dev sys proc; do sudo umount /mnt/rpi_root/$fs || true; done
sudo umount /mnt/rpi_boot || true
sudo umount /mnt/rpi_root || true
if command -v kpartx >/dev/null 2>&1; then sudo kpartx -d "$IMG" || true; fi
sudo losetup -d "$LOOPDEV" || true

echo "Image bereit: $IMG"
