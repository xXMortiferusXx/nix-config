#!/usr/bin/env bash
set -euo pipefail

# --- KONFIGURATION ---
REPO_URL="https://github.com/xXMortiferusXx/nix-config.git"
# ---------------------

# Farben für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- SCHRITT 0: Internet-Check ---
info "Prüfe Internetverbindung..."
if ! ping -c 1 8.8.8.8 &>/dev/null; then
    error "Keine Internetverbindung erkannt! Bitte verbinde dich über nmtui mit dem WLAN/LAN."
fi

# --- SCHRITT 1: Host-Auswahl ---
echo "=========================================================="
echo "  Mortiferus NixOS Multi-Host Installer"
echo "=========================================================="
echo ""
echo "Welches System soll installiert werden?"
echo "  1) nex (Haupt-PC / mortiferus)"
echo "  2) styx (Office-PC / backbone)"
echo ""
read -p "Auswahl [1-2]: " HOST_CHOICE

if [[ "$HOST_CHOICE" == "1" ]]; then
    HOSTNAME="nex"
    USERNAME="mortiferus"
    DISK_DEVICE="/dev/nvme0n1"
elif [[ "$HOST_CHOICE" == "2" ]]; then
    HOSTNAME="styx"
    USERNAME="backbone"
    DISK_DEVICE="/dev/nvme0n1"
else
    error "Ungültige Auswahl."
fi

info "Installiere Host: $HOSTNAME für User: $USERNAME auf $DISK_DEVICE"

# --- SCHRITT 2: Voraussetzungen prüfen ---
info "Prüfe Voraussetzungen..."

if ! command -v git &> /dev/null; then
    warn "Git fehlt. Lade temporäre Nix-Shell..."
    exec nix-shell -p git --run "$(readlink -f "$0")"
    exit
fi

if [ "$(id -u)" -eq 0 ]; then
    error "Bitte das Skript NICHT als root ausführen (sudo wird automatisch verwendet)."
fi

# --- SCHRITT 3: Konfiguration laden ---
info "Klone Repository..."
rm -rf /tmp/nixos-config
git clone "$REPO_URL" /tmp/nixos-config
cd /tmp/nixos-config

# --- SCHRITT 4: Partitionieren & Mounten ---
info "Bereite Festplatte vor (löse bestehende Sperren)..."
sudo umount -R /mnt 2>/dev/null || true
sudo swapoff -a 2>/dev/null || true

info "Partitioniere und mounte ${DISK_DEVICE}..."

sudo nix --experimental-features "nix-command flakes" \
    --option download-buffer-size 268435456 \
    --option connect-timeout 20 \
    run github:nix-community/disko -- \
    --mode disko \
    --mode zap_create_mount \
    --argstr device "$DISK_DEVICE" \
    --flake ".#$HOSTNAME"

# --- NEU: SWAP AKTIVIEREN GEGEN OOM ---
info "Aktiviere Swap zur RAM-Entlastung..."
if [ -f /mnt/swap/swapfile ]; then
    sudo swapon /mnt/swap/swapfile || warn "Konnte Swapfile nicht aktivieren."
fi

# --- SCHRITT 5: Dateien nach /mnt kopieren ---
info "Kopiere Konfiguration nach /mnt..."
sudo mkdir -p /mnt/etc/nixos
sudo cp -r . /mnt/etc/nixos/
sudo rm -rf /mnt/etc/nixos/.git

# --- SCHRITT 6: Installation ---
info "Starte NixOS-Installation für $HOSTNAME..."
sudo nixos-install --flake "/mnt/etc/nixos#$HOSTNAME" \
    --option download-buffer-size 268435456 \
    --option connect-timeout 20 \
    --no-root-passwd --no-channel-copy

# --- SCHRITT 7: Rechte & Git-Setup ---
info "Bereite Zielsystem vor (Rechte & Git)..."
# Setze Rechte für den User
sudo nixos-enter --root /mnt -c "chown -R $USERNAME:users /etc/nixos"

# Initialisiere Git im Zielsystem, damit Flakes sofort funktionieren
sudo nixos-enter --root /mnt -c "cd /etc/nixos && git init && git remote add origin $REPO_URL && git add ."

echo ""
echo "=========================================================="
echo "  Passwörter setzen"
echo "=========================================================="
echo ""

echo "Passwort für ROOT setzen:"
sudo nixos-enter --root /mnt -c "passwd root"

echo ""
echo "Passwort für $USERNAME setzen:"
sudo nixos-enter --root /mnt -c "passwd $USERNAME"

echo ""
echo "=========================================================="
echo "  INSTALLATION VON $HOSTNAME ABGESCHLOSSEN!"
echo "=========================================================="
echo ""
echo "Nächste Schritte nach dem Reboot:"
echo "  1. Einloggen als $USERNAME"
echo "  2. SSH-Key erstellen und bei GitHub hinterlegen"
echo "  3. Config ist bereits unter /etc/nixos als Git-Repo bereit"
echo ""
echo "Du kannst jetzt 'reboot' tippen."
echo "=========================================================="
