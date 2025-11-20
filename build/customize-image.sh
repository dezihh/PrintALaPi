#!/usr/bin/env bash
set -euo pipefail

# build/customize-image.sh
# Usage:
#   Outside chroot: ./build/customize-image.sh <raspios-archive-or-img> [<path-to-repo-root>]
#   Inside chroot:  ./build/customize-image.sh --in-chroot
#
# Dieses Script:
# - erkennt .img/.img.xz/.xz/.img.gz/.gz/.zip automatisch und dekomprimiert in ein Tempdir
# - hängt die Image-Partitionen ein, kopiert das Repo nach /opt/printalapy
# - richtet qemu-arm-static + bind-mounts ein und chrootet
# - führt im Chroot die Setup-Skripte aus (scripts/setup.sh oder einzelne setup-* Skripte)
# - räumt sauber auf

REPO_HINT="${2:-}"   # optionaler Pfad zum Repo root, default ist parent vom build dir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_HINT:-$(realpath "${SCRIPT_DIR}/..")}"

# If called inside chroot:
if [ "${1:-}" = "--in-chroot" ]; then
  echo "== In-Chroot: Konfiguration im Image ausführen =="
  set -x
  # Minimal: update & run repo setup scripts (non-interactive if possible)
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y || true
    # install useful packages in chroot if scripts expect them
    apt-get install -y --no-install-recommends ca-certificates rsync || true
  fi

  # Prefer main setup script if present
  if [ -x /opt/printalapy/scripts/setup.sh ]; then
    echo "Running /opt/printalapy/scripts/setup.sh"
    /opt/printalapy/scripts/setup.sh || true
  else
    echo "Kein scripts/setup.sh gefunden, versuche einzelne setup-*.sh"
    for s in /opt/printalapy/scripts/setup-*.sh; do
      [ -f "$s" ] || continue
      echo "Running $s"
      chmod +x "$s" || true
      "$s" || true
    done
  fi

  echo "In-Chroot tasks abgeschlossen."
  exit 0
fi

# Outside-chroot flow:
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <image-archive-or-img> [<repo-root>]"
  exit 2
fi

ARCHIVE="$1"
TMPDIR="$(mktemp -d)"
cleanup() {
  set +e
  echo "== Cleanup =="
  # unmount any mounts in TMPMOUNT
  if mountpoint -q /mnt/rpi_root/run 2>/dev/null; then umount /mnt/rpi_root/run; fi
  for fs in dev proc sys
