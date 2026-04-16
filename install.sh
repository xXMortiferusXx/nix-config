#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/xXMortiferusXx/nix-config.git"
HOSTNAME="Mortiferus-PC"

# 1. Git besorgen
if ! command -v git &> /dev/null; then
    exec nix-shell -p git --run "$(readlink -f "$0")"
    exit
fi

# 2. Repo in RAM klonen
echo "Klone Repo..."
rm -rf /tmp/nixos-config && git clone "$REPO_URL" /tmp/nixos-config
cd /tmp/nixos-config

# 3. Festplatte vorbereiten (Mountet alles nach /mnt)
echo "Partitioniere..."
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --argstr device "/dev/nvme0n1" --flake ".#$HOSTNAME"

# 4. Dateien ins Zielsystem kopieren, BEVOR wir installieren
echo "Bereite /etc/nixos vor..."
sudo mkdir -p /mnt/etc/nixos
sudo cp -r . /mnt/etc/nixos/

# 5. Installation starten (Wir referenzieren die Kopie auf der SSD)
echo "Installiere NixOS..."
sudo nixos-install --flake "/mnt/etc/nixos#$HOSTNAME" --no-root-passwd

# 6. Rechte & Passwörter
echo "Finalisiere..."
sudo chroot /mnt chown -R mortiferus:users /etc/nixos
sudo nixos-enter --root /mnt -c "passwd root"
sudo nixos-enter --root /mnt -c "passwd mortiferus"

echo "Reboot bereit!"
