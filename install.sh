#!/usr/bin/env bash
set -e

# --- KONFIGURATION ---
REPO_URL="https://github.com/xXMortiferusXx/nix-config.git"
HOSTNAME="Mortiferus-PC"
# ---------------------

# 1. Git für den Klon-Vorgang sicherstellen
if ! command -v git &> /dev/null; then
    echo "Git fehlt. Lade temporäre Nix-Shell..."
    exec nix-shell -p git --run "$(readlink -f "$0")"
    exit
fi

echo "--- SCHRITT 1: Konfiguration laden ---"
rm -rf /tmp/nixos-config
git clone "$REPO_URL" /tmp/nixos-config
cd /tmp/nixos-config

echo "--- SCHRITT 2: Partitionieren & Mounten ---"
# Disko bereitet /mnt vor
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --argstr device "/dev/nvme0n1" --flake ".#$HOSTNAME"

echo "--- SCHRITT 3: Dateien vorbereiten ---"
sudo mkdir -p /mnt/etc/nixos
sudo cp -r . /mnt/etc/nixos/
# Git-Ordner löschen, um Flake-Probleme im Installer zu vermeiden
sudo rm -rf /mnt/etc/nixos/.git

echo "--- SCHRITT 4: Installation ---"
# Wir installieren vom Pfad auf der SSD
sudo nixos-install --flake "/mnt/etc/nixos#$HOSTNAME" --no-root-passwd

echo "--- SCHRITT 5: Rechte & Passwörter ---"
# User-ID 1000 (mortiferus) den Ordner zuteilen
sudo chroot /mnt chown -R 1000:users /etc/nixos

echo "Passwort für ROOT setzen:"
sudo nixos-enter --root /mnt -c "passwd root"

echo "Passwort für mortiferus setzen:"
sudo nixos-enter --root /mnt -c "passwd mortiferus"

echo "-----------------------------------------------------"
echo "INSTALLATION FERTIG!"
echo "Nach dem Reboot:"
echo "1. ssh-keygen -t ed25519 -C \"deine@email.de\""
echo "2. Key bei GitHub hinterlegen"
echo "3. cd /etc/nixos && git init && git remote add origin $REPO_URL"
echo "-----------------------------------------------------"
