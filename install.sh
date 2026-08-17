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
echo "  3) test (QEMU-Test / test)"
echo ""
read -p "Auswahl [1-3]: " HOST_CHOICE

if [[ "$HOST_CHOICE" == "1" ]]; then
    HOSTNAME="nex"
    USERNAME="mortiferus"
elif [[ "$HOST_CHOICE" == "2" ]]; then
    HOSTNAME="styx"
    USERNAME="backbone"
elif [[ "$HOST_CHOICE" == "3" ]]; then
    HOSTNAME="test"
    USERNAME="test"
else
    error "Ungültige Auswahl."
fi

info "Installiere Host: $HOSTNAME für User: $USERNAME"

# --- SCHRITT 1b: NVMe-Laufwerksauswahl (SICHERHEIT) ---
# Problem: Linux erkennt NVMe-Geräte nicht immer in gleicher Reihenfolge
# (nvme0 vs. nvme1). Daher NIE hart verdrahten, sondern immer interaktiv
# anhand von Modell + Seriennummer + Label auswählen!
echo ""
echo "=========================================================="
echo "  NVMe-Laufwerksauswahl"
echo "=========================================================="
echo ""
echo "Erkannte NVMe-Laufwerke:"
echo "----------------------------------------------------------"

mapfile -t NVME_DEVICES < <(lsblk -d -n -o NAME,SIZE,MODEL,SERIAL,LABEL | awk '$1 ~ /^nvme/')

if [ ${#NVME_DEVICES[@]} -eq 0 ]; then
    error "Keine NVMe-Laufwerke gefunden! Abgebrochen."
fi

for i in "${!NVME_DEVICES[@]}"; do
    echo "  [$((i+1))] ${NVME_DEVICES[$i]}"
done
echo "----------------------------------------------------------"
echo ""
read -p "Welches Laufwerk soll installiert werden? [1-${#NVME_DEVICES[@]}]: " DISK_CHOICE

if ! [[ "$DISK_CHOICE" =~ ^[0-9]+$ ]] || [ "$DISK_CHOICE" -lt 1 ] || [ "$DISK_CHOICE" -gt "${#NVME_DEVICES[@]}" ]; then
    error "Ungültige Auswahl."
fi

DISK_NAME=$(echo "${NVME_DEVICES[$((DISK_CHOICE-1))]}" | awk '{print $1}')
DISK_MODEL=$(echo "${NVME_DEVICES[$((DISK_CHOICE-1))]}" | awk '{print $3}')
DISK_SERIAL=$(echo "${NVME_DEVICES[$((DISK_CHOICE-1))]}" | awk '{print $4}')
DISK_LABEL=$(echo "${NVME_DEVICES[$((DISK_CHOICE-1))]}" | awk '{print $5}')
DISK_DEVICE="/dev/${DISK_NAME}"

# Warnung, falls das gewählte Laufwerk ein Label hat (z.B. GamingDrive auf nex)
if [ -n "$DISK_LABEL" ] && [ "$DISK_LABEL" != "-" ]; then
    warn "Gewähltes Laufwerk hat ein Dateisystem-Label: $DISK_LABEL"
fi

echo ""
warn "ACHTUNG: $DISK_DEVICE wird KOMPLETT GELÖSCHT und neu partitioniert!"
echo "  Modell:      $DISK_MODEL"
echo "  Seriennummer: $DISK_SERIAL"
echo "  Label:       ${DISK_LABEL:--}"
echo ""
read -p "Soll das WIRKLICH dieses Laufwerk sein? (ja/NEIN): " CONFIRM
if [[ "$CONFIRM" != "ja" ]]; then
    error "Abgebrochen. Bitte Skript erneut starten und richtiges Laufwerk wählen."
fi

info "Installiere auf: $DISK_DEVICE (Modell: $DISK_MODEL)"

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
    --mode destroy,format,mount \
    --argstr device "$DISK_DEVICE" \
    --flake ".#$HOSTNAME"

# --- TEMPORÄRER SWAP GEGEN OOM (nur für die Installation) ---
# Die disko-Configs haben KEINEN dauerhaften Swap (System läuft ZRAM-only).
# Für den nixos-install-Build kann viel RAM nötig sein (OOM-Risiko).
# Daher legen wir hier ein temporäres Swapfile auf /mnt an, aktivieren es
# für die Installation und entfernen es danach wieder — es landet also
# NIE im installierten System.
SWAPFILE="/mnt/.install-swapfile"

cleanup_swap() {
    sudo swapoff "$SWAPFILE" 2>/dev/null || true
    sudo rm -f "$SWAPFILE" 2>/dev/null || true
}
trap cleanup_swap EXIT

setup_swap() {
    if command -v free &>/dev/null; then
        local ram_mb
        ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    else
        local ram_mb
        ram_mb=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
    fi

    # Swap = 2x RAM (max 16G), damit der Build nie an RAM scheitert
    local swap_mb=$(( ram_mb * 2 ))
    [ "$swap_mb" -gt 16384 ] && swap_mb=16384

    info "Lege temporäres Swapfile an (${swap_mb}MB, nur für die Installation)..."
    sudo truncate -s "${swap_mb}M" "$SWAPFILE"
    sudo chmod 600 "$SWAPFILE"
    sudo mkswap "$SWAPFILE" >/dev/null
    sudo swapon "$SWAPFILE" || { warn "Swapfile konnte nicht aktiviert werden — weiter ohne Swap (OOM-Risiko)"; sudo rm -f "$SWAPFILE"; }
}

setup_swap

# --- DYNAMISCHE BUILD-KONFIGURATION BASIEREND AUF RAM ---
info "Ermittle dynamische Build-Konfiguration..."

if command -v free &>/dev/null; then
    TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
else
    TOTAL_RAM_MB=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
fi

NPROC=$(nproc)

# Sicherheitsfaktor: pro parallelem Job mindestens 3 GB RAM einplanen
MAX_JOBS=$(( TOTAL_RAM_MB / 3072 ))
[ "$MAX_JOBS" -lt 1 ] && MAX_JOBS=1
[ "$MAX_JOBS" -gt "$NPROC" ] && MAX_JOBS="$NPROC"

# Cores so wählen, dass wir bei wenig RAM nicht alle Kerne blockieren
CORES=$(( NPROC / MAX_JOBS ))
[ "$CORES" -lt 1 ] && CORES=1
[ "$CORES" -gt "$NPROC" ] && CORES="$NPROC"

info "RAM: ${TOTAL_RAM_MB}MB | CPU-Kerne: $NPROC | max-jobs: $MAX_JOBS | cores: $CORES"

# --- SCHRITT 5: Dateien nach /mnt kopieren ---
info "Kopiere Konfiguration nach /mnt..."
sudo mkdir -p /mnt/etc/nixos
sudo cp -r . /mnt/etc/nixos/
sudo rm -rf /mnt/etc/nixos/.git

# --- SCHRITT 6: Installation ---
info "Starte NixOS-Installation für $HOSTNAME..."
sudo nixos-install --flake "/mnt/etc/nixos#$HOSTNAME" \
    --option max-jobs "$MAX_JOBS" \
    --option cores "$CORES" \
    --option download-buffer-size 268435456 \
    --option connect-timeout 20 \
    --no-root-passwd --no-channel-copy

# --- WLAN-VERBINDUNGEN VOM LIVE-SYSTEM ÜBERNEHMEN ---
info "Kopiere NetworkManager-Verbindungen vom Live-System..."
if [ -d /etc/NetworkManager/system-connections ]; then
    CONNECTIONS=$(ls /etc/NetworkManager/system-connections/*.nmconnection 2>/dev/null || true)
    if [ -n "$CONNECTIONS" ]; then
        sudo mkdir -p /mnt/etc/NetworkManager/system-connections
        sudo cp /etc/NetworkManager/system-connections/*.nmconnection /mnt/etc/NetworkManager/system-connections/
        sudo chown -R root:root /mnt/etc/NetworkManager/system-connections/
        sudo chmod 600 /mnt/etc/NetworkManager/system-connections/*.nmconnection 2>/dev/null || true
        info "WLAN-Verbindung(en) erfolgreich kopiert."
    else
        warn "Keine .nmconnection-Dateien im Live-System gefunden."
    fi
else
    warn "NetworkManager system-connections Verzeichnis nicht gefunden."
fi

# --- SCHRITT 7: Rechte & Git-Setup ---
info "Bereite Zielsystem vor (Rechte & Git)..."
# Setze Rechte für den User
sudo nixos-enter --root /mnt -c "chown -R $USERNAME:users /etc/nixos"

# Initialisiere Git im Zielsystem, damit Flakes sofort funktionieren
REMOTE_URL="https://github.com/xXMortiferusXx/nix-config.git"
if [[ "$HOSTNAME" == "nex" ]]; then
    REMOTE_URL="git@github.com:xXMortiferusXx/nix-config.git"
fi
sudo nixos-enter --root /mnt -c "cd /etc/nixos && git init && git branch -M main && git remote add origin $REMOTE_URL && git add ."

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
