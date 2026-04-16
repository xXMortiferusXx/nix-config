#!/usr/bin/env bash
set -e

# --- ANPASSEN ---
REPO_URL="https://github.com/xXMortiferusXx/nix-config.git"
HOSTNAME="Mortiferus-PC"
# ----------------

if ! command -v git &> /dev/null; then
    echo "Git fehlt. Starte temporäre Nix-Shell..."
    exec nix-shell -p git --run "$(readlink -f "$0")"
    exit
fi

echo "Klone Konfiguration..."
rm -rf /tmp/nixos-config
git clone "$REPO_URL" /tmp/nixos-config
cd /tmp/nixos-config

echo "Führe Disko aus (Formatierung nvme0n1)..."
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --argstr device "/dev/nvme0n1" --flake ".#$HOSTNAME"

echo "Starte NixOS Installation..."
sudo nixos-install --flake ".#$HOSTNAME" --no-root-passwd

echo "Kopiere Files nach /etc/nixos..."
sudo mkdir -p /mnt/etc/nixos
sudo cp -r . /mnt/etc/nixos/
# Setze Besitzer auf mortiferus (ID 1000)
sudo chroot /mnt chown -R mortiferus:users /etc/nixos

echo "--- PASSWORT-EINGABE ---"
echo "Passwort für ROOT setzen:"
sudo nixos-enter --root /mnt -c "passwd root"

echo "Passwort für mortiferus setzen:"
sudo nixos-enter --root /mnt -c "passwd mortiferus"

echo "Installation abgeschlossen. Du kannst jetzt 'reboot' tippen."
