#!/usr/bin/env bash
set -euo pipefail

ARCHIVE="$1"
TMPDIR="$(mktemp -d)"
cleanup(){ rm -rf "$TMPDIR"; }
trap cleanup EXIT

# ensure helpers
sudo apt-get update -y
sudo apt-get install -y xz-utils unzip gzip file || true

# prefer explicit suffix checks first (handles .img.xz, .img.gz, .img.zip)
case "$ARCHIVE" in
  *.img.xz) echo "Found .img.xz -> unxz keeping original"; cp "$ARCHIVE" "$TMPDIR/"; (cd "$TMPDIR" && xz -d -k "$(basename "$ARCHIVE")"); IMG_CAND="$TMPDIR/$(basename "${ARCHIVE%.xz}")";;
  *.img.gz) echo "Found .img.gz -> gunzip keeping original"; cp "$ARCHIVE" "$TMPDIR/"; (cd "$TMPDIR" && gunzip -k "$(basename "$ARCHIVE")"); IMG_CAND="$TMPDIR/$(basename "${ARCHIVE%.gz}")";;
  *.img.zip) echo "Found .img.zip -> unzip"; unzip -d "$TMPDIR" "$ARCHIVE"; IMG_CAND="$(find "$TMPDIR" -type f -name '*.img' -print -quit)";;
  *.xz) echo "Found .xz -> try to extract .img inside"; cp "$ARCHIVE" "$TMPDIR/"; (cd "$TMPDIR" && xz -d -k "$(basename "$ARCHIVE")"); IMG_CAND="$(find "$TMPDIR" -type f -name '*.img' -print -quit)";;
  *.gz) echo "Found .gz -> try to extract .img inside"; cp "$ARCHIVE" "$TMPDIR/"; (cd "$TMPDIR" && gunzip -k "$(basename "$ARCHIVE")"); IMG_CAND="$(find "$TMPDIR" -type f -name '*.img' -print -quit)";;
  *.zip) echo "Found .zip -> unzip"; unzip -d "$TMPDIR" "$ARCHIVE"; IMG_CAND="$(find "$TMPDIR" -type f -name '*.img' -print -quit)";;
  *.img) IMG_CAND="$(realpath "$ARCHIVE")";;
  *) 
    # fallback: inspect MIME/type then try extensions
    MIME=$(file --brief --mime-type "$ARCHIVE" || echo "")
    case "$MIME" in
      application/x-xz|application/x-xz-compressed) cp "$ARCHIVE" "$TMPDIR" && (cd "$TMPDIR" && xz -d -k "$(basename "$ARCHIVE")") && IMG_CAND="$(find "$TMPDIR" -type f -name '*.img' -print -quit)";;
      application/gzip) cp "$ARCHIVE" "$TMPDIR" && (cd "$TMPDIR" && gunzip -k "$(basename "$ARCHIVE")") && IMG_CAND="$(find "$TMPDIR" -type f -name '*.img' -print -quit)";;
      application/zip) unzip -d "$TMPDIR" "$ARCHIVE" && IMG_CAND="$(find "$TMPDIR" -type f -name '*.img' -print -quit)";;
      *) echo "Unknown format; try passing .img/.img.xz/.img.gz/.zip explicitly"; exit 2;;
    esac
    ;;
esac

if [ -z "${IMG_CAND:-}" ] || [ ! -f "$IMG_CAND" ]; then
  echo "Keine .img-Datei gefunden nach Dekompression."
  exit 3
fi

IMG="$(realpath "$IMG_CAND")"
echo "Using image: $IMG"
# ...weiter wie zuvor (losetup/kpartx/mount/chroot)...
