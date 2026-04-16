#!/usr/bin/env bash
set -e

# --- KONFIGURATION ---
REPO_URL="https://github.com/xXMortiferusXx/nix-config.git"
HOSTNAME="Mortiferus-PC"
# ---------------------

echo "--- SCHRITT 1: Vorbereitung der Umgebung ---"
# Falls Disko schon gemountet hat, nutzen wir das.
if ! findmnt /mnt > /dev/null; then
    echo "Partitionen nicht gemountet. Starte Disko..."
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake "$REPO_URL#$HOSTNAME"
fi

echo "--- SCHRITT 2: Config abholen & Lock-File fixen ---"
# Wir arbeiten im RAM (/tmp), um Konflikte mit dem Git-Status zu vermeiden
sudo rm -rf /tmp/nixos-config
git clone "$REPO_URL" /tmp/nixos-config
cd /tmp/nixos-config

# Hier passiert die Magie: Wir erzwingen ein Update der Lockfile, 
# damit die Hashes garantiert zum aktuellen Live-System passen.
echo "Aktualisiere Abhängigkeiten (flake.lock)..."
sudo nix --experimental-features "nix-command flakes" flake update

echo "--- SCHRITT 3: Kopieren der Config nach /mnt ---"
sudo mkdir -p /mnt/etc/nixos
sudo cp -r . /mnt/etc/nixos/
sudo rm -rf /mnt/etc/nixos/.git

echo "--- SCHRITT 4: Installation ---"
# Wir nutzen --no-write-lock-file, damit Nix nicht versucht, 
# während der Installation auf dem Read-Only Medium zu schreiben.
sudo nixos-install --flake "/mnt/etc/nixos#$HOSTNAME" --no-root-passwd

echo "--- SCHRITT 5: Benutzer-Passwörter ---"
# Da wir vollautomatisch sein wollen, setzen wir ein temporäres Passwort "nixos"
# Das kannst du nach dem ersten Boot sofort mit 'passwd' ändern.
echo "Setze temporäre Passwörter (User: nixos, Root: nixos)..."
echo "root:nixos" | sudo nixos-enter --root /mnt -- chpasswd
echo "mortiferus:nixos" | sudo nixos-enter --root /mnt -- chpasswd

echo "-----------------------------------------------------------"
echo "INSTALLATION ABGESCHLOSSEN!"
echo "Du kannst jetzt 'reboot' tippen."
echo "WICHTIG: Deine Passwörter sind aktuell beide 'nixos'."
echo "-----------------------------------------------------------"#!/usr/bin/env bash
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
