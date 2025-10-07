#! /usr/bin/bash

set -euo pipefail

# Variables
KREL="$(uname -r)"
EVDI_VER="${EVDI_VER:-1.14.10}"
MOK_DER="/var/lib/dkms/MOK.der"
MOK_PRIV="/var/lib/dkms/MOK.priv"
BDIR="/var/lib/dkms/evdi/$EVDI_VER/$KREL/x86_64/module"
DEST="/lib/modules/$KREL/extra/evdi.ko"

echo "*** Kernel: $KREL | EVDI: $EVDI_VER ***"

# Sanity check, keys present
[[ -f "$MOK_DER" && -f "$MOK_PRIV" ]] || { echo "Missing MOK.der or MOK.priv, aborting..."; exit 1; }
echo "Machine Owner Key found."

# Rebuild evdi for current kernel
sudo dkms autoinstall -k "$KREL"
echo "Finished rebuilding evdi for current kernel."

# Sanity check, dir exists
[[ -d "$BDIR" ]] || { echo "Build dir not found, aborting..."; exit 1; }
pushd "$BDIR" >/dev/null

# Uncompress evdi.ko.xz
if [[ ! -f evdi.ko ]] ; then
  [[ -f evdi.ko.xz ]] || { echo "No evdi.ko or evdi.ko.xz in $BDIR, aborting..."; exit 1; }
  sudo xz -d -k evdi.ko.xz
fi
[[ -f evdi.ko ]] || { echo "Failed to produce evdi.ko, aborting..."; exit 1; }
echo "Uncompressed evdi.ko file successfully!"

# Sign the raw module with enrolled MOK
sudo /usr/src/kernels/"$KREL"/scripts/sign-file sha256 "$MOK_PRIV" "$MOK_DER" evdi.ko
echo "Signer: $(modinfo -F signer ./evdi.ko 2>/dev/null || echo 'Signer could not read signature.')"
popd >/dev/null
echo "Raw module signed with enrolled MOK, installing evdi.ko and running depmod.."

# Install the signed evdi.ko into modules tree + depmod
sudo install -D -m 0644 "$BDIR/evdi.ko" "$DEST"
sudo find "/lib/modules/$KREL" -path "*/extra/evdi.ko.xz" -delete 2>/dev/null || true
sudo depmod -a

# Load module
echo "Loading module and checking lsmod"
sudo modprobe -r evdi 2>/dev/null || true
sudo modprobe -v evdi
lsmod | grep -i evdi || { echo "evdi failed to load, aborting"; exit 1; }

# Restart service
echo "Restarting displaylink-driver service."
sudo systemctl restart displaylink-driver.service
sudo systemctl status  displaylink-driver.service

echo "Evdi successfully reinstalled for current kernel: $KREL"
