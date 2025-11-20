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
MOUNT_POINT="/mnt/rpi_root"

cleanup() {
  set +e
  echo "== Cleanup =="
  # unmount any mounts in MOUNT_POINT
  if mountpoint -q "${MOUNT_POINT}/run" 2>/dev/null; then umount "${MOUNT_POINT}/run"; fi
  for fs in dev proc sys; do
    if mountpoint -q "${MOUNT_POINT}/${fs}" 2>/dev/null; then 
      umount "${MOUNT_POINT}/${fs}"
    fi
  done
  
  # Unmount boot and root partitions
  if mountpoint -q "${MOUNT_POINT}/boot" 2>/dev/null; then umount "${MOUNT_POINT}/boot"; fi
  if mountpoint -q "${MOUNT_POINT}" 2>/dev/null; then umount "${MOUNT_POINT}"; fi
  
  # Remove loop devices
  if [ -n "${LOOP_DEV:-}" ]; then
    kpartx -d "${LOOP_DEV}" 2>/dev/null || true
    losetup -d "${LOOP_DEV}" 2>/dev/null || true
  fi
  
  # Clean up temp directory
  if [ -n "${TMPDIR:-}" ] && [ -d "${TMPDIR}" ]; then
    rm -rf "${TMPDIR}"
  fi
  
  echo "Cleanup complete"
}

trap cleanup EXIT

# Extract/decompress image if needed
IMG_FILE="${TMPDIR}/image.img"
echo "Processing archive: ${ARCHIVE}"

if [[ "${ARCHIVE}" =~ \.img$ ]]; then
  # Already an .img file
  cp "${ARCHIVE}" "${IMG_FILE}"
elif [[ "${ARCHIVE}" =~ \.(img\.xz|xz)$ ]]; then
  echo "Decompressing xz archive..."
  xz -dc "${ARCHIVE}" > "${IMG_FILE}"
elif [[ "${ARCHIVE}" =~ \.(img\.gz|gz)$ ]]; then
  echo "Decompressing gzip archive..."
  gzip -dc "${ARCHIVE}" > "${IMG_FILE}"
elif [[ "${ARCHIVE}" =~ \.zip$ ]]; then
  echo "Extracting zip archive..."
  unzip -p "${ARCHIVE}" > "${IMG_FILE}"
else
  echo "Error: Unsupported archive format"
  exit 1
fi

# Setup loop device and mount partitions
echo "Setting up loop device..."
LOOP_DEV=$(losetup -fP --show "${IMG_FILE}")
echo "Loop device: ${LOOP_DEV}"

# Wait for partitions to appear
sleep 2

# Create mount point
mkdir -p "${MOUNT_POINT}"

# Mount root partition (usually partition 2)
echo "Mounting root partition..."
mount "${LOOP_DEV}p2" "${MOUNT_POINT}"

# Mount boot partition
echo "Mounting boot partition..."
mkdir -p "${MOUNT_POINT}/boot"
mount "${LOOP_DEV}p1" "${MOUNT_POINT}/boot"

# Copy repository to image
echo "Copying PrintALaPi files to image..."
mkdir -p "${MOUNT_POINT}/opt/printalapy"
rsync -av --exclude='.git' --exclude='build' "${REPO_DIR}/" "${MOUNT_POINT}/opt/printalapy/"

# Setup for chroot
echo "Preparing chroot environment..."
cp /usr/bin/qemu-arm-static "${MOUNT_POINT}/usr/bin/" 2>/dev/null || echo "qemu-arm-static not found, skipping"

# Mount virtual filesystems
mount -t proc proc "${MOUNT_POINT}/proc"
mount -t sysfs sys "${MOUNT_POINT}/sys"
mount -o bind /dev "${MOUNT_POINT}/dev"
mount -o bind /dev/pts "${MOUNT_POINT}/dev/pts" 2>/dev/null || true

# Run setup in chroot
echo "Running setup scripts in chroot..."
chroot "${MOUNT_POINT}" /opt/printalapy/build/customize-image.sh --in-chroot

# Create output image
echo "Creating output image..."
OUTPUT_IMG="${SCRIPT_DIR}/printalapy.img"
cp "${IMG_FILE}" "${OUTPUT_IMG}"

echo "Build complete! Output: ${OUTPUT_IMG}"
