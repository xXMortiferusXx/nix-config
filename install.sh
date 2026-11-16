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

# --- INSTALLATIONS-DNS ---
# Die Live-Sitzung nutzt bewusst öffentliche Resolver. Ein vom Router
# vorgegebener DNS (Fritzbox-Filter, Pi-hole, Rebind-Schutz) soll die
# Installation nicht blockieren. Gilt NUR für die Live-Sitzung: weder
# /etc/resolv.conf noch die NetworkManager-Profile werden ins Zielsystem
# übernommen. Überschreibbar mit --dns <ip[,ip]> bzw. --dns off.
INSTALL_DNS=(1.1.1.1 9.9.9.9)

# --- TEMPORÄRE RESSOURCEN (werden bei Ende/Abbruch zurückgebaut) ---
SWAPFILE="/mnt/.install-swapfile"
DNS_KEY="install-dns"
DNS_ACTIVE=0
DNS_MODE=""
DNS_BACKUP=""

cleanup_install_dns() {
    [ "${DNS_ACTIVE}" -eq 1 ] || return 0
    if [ "${DNS_MODE}" = "resolvconf" ]; then
        sudo resolvconf -d "${DNS_KEY}" 2>/dev/null || true
    elif [ -n "${DNS_BACKUP}" ]; then
        sudo rm -f /etc/NetworkManager/conf.d/90-install-dns.conf 2>/dev/null || true
        sudo nmcli general reload conf >/dev/null 2>&1 || true
        sudo cp "${DNS_BACKUP}" /etc/resolv.conf 2>/dev/null || true
        rm -f "${DNS_BACKUP}"
    fi
    DNS_ACTIVE=0
}

cleanup_swap() {
    sudo swapoff "${SWAPFILE}" 2>/dev/null || true
    sudo rm -f "${SWAPFILE}" 2>/dev/null || true
}

cleanup_all() {
    cleanup_install_dns
    cleanup_swap
}
trap cleanup_all EXIT

# --- OPTIONEN ---
while [ $# -gt 0 ]; do
    case "$1" in
        --dns)
            [ $# -ge 2 ] || error "--dns braucht einen Wert (IP oder 'off')."
            if [ "$2" = "off" ] || [ "$2" = "none" ]; then
                INSTALL_DNS=()
            else
                IFS=',' read -r -a INSTALL_DNS <<< "$2"
            fi
            shift 2
            ;;
        --dns=*)
            val="${1#*=}"
            if [ "$val" = "off" ] || [ "$val" = "none" ]; then
                INSTALL_DNS=()
            else
                IFS=',' read -r -a INSTALL_DNS <<< "$val"
            fi
            shift
            ;;
        -h|--help)
            echo "Aufruf: $0 [--dns <ip[,ip]>|off]"
            echo "  --dns IP    Resolver für die Installation (Standard: 1.1.1.1,9.9.9.9)"
            echo "  --dns off   Router-/DHCP-DNS verwenden"
            exit 0
            ;;
        *)
            error "Unbekannte Option: $1 (erlaubt: --dns <ip[,ip]>|off)"
            ;;
    esac
done

for ns in "${INSTALL_DNS[@]}"; do
    [[ "$ns" =~ ^[0-9a-fA-F:.]+$ ]] || error "Ungültige DNS-Adresse: $ns"
done

# Setzt den Installations-DNS über openresolv (die ISO nutzt NetworkManager +
# openresolv). `-m 0` = höchste Priorität, `-x` = exklusiv: der Router-DNS wird
# während der Installation komplett ignoriert. Fällt openresolv aus oder
# schreibt es die Datei nicht, wird /etc/resolv.conf direkt geschrieben
# (Original wird gesichert und im EXIT-Trap zurückgespielt).
dns_in_file() {
    local ns
    for ns in "${INSTALL_DNS[@]}"; do
        grep -qx "nameserver ${ns}" /etc/resolv.conf 2>/dev/null || return 1
    done
    return 0
}

set_install_dns() {
    if [ "${#INSTALL_DNS[@]}" -eq 0 ]; then
        info "Installations-DNS: aus (Router-/DHCP-DNS wird verwendet)."
        return 0
    fi

    local rc_ok=0
    if command -v resolvconf >/dev/null 2>&1; then
        if printf 'nameserver %s\n' "${INSTALL_DNS[@]}" \
            | sudo resolvconf -m 0 -x -a "${DNS_KEY}" 2>/dev/null; then
            if dns_in_file; then
                DNS_MODE="resolvconf"
                rc_ok=1
            else
                # Key wieder entfernen, sonst bleibt ein wirkungsloser Eintrag.
                sudo resolvconf -d "${DNS_KEY}" 2>/dev/null || true
            fi
        fi
    fi

    if [ "${rc_ok}" -eq 0 ]; then
        DNS_BACKUP=$(mktemp)
        sudo cp /etc/resolv.conf "${DNS_BACKUP}" 2>/dev/null || true
        printf 'nameserver %s\noptions timeout:2 attempts:2\n' "${INSTALL_DNS[@]}" \
            | sudo tee /etc/resolv.conf >/dev/null
        # Verhindern, dass NetworkManager/openresolv die Datei bei einem
        # DHCP-Renew wieder überschreibt (betrifft nur die Live-Sitzung).
        sudo mkdir -p /etc/NetworkManager/conf.d
        printf '[main]\nrc-manager=unmanaged\n' \
            | sudo tee /etc/NetworkManager/conf.d/90-install-dns.conf >/dev/null
        sudo nmcli general reload conf >/dev/null 2>&1 || true
        DNS_MODE="file"
    fi

    DNS_ACTIVE=1
    info "Installations-DNS: ${INSTALL_DNS[*]} (nur Live-Sitzung, Modus: ${DNS_MODE})"
}

# Prüft den Weg, den die Installation tatsächlich nimmt. ping war untauglich:
# viele Router verwerfen ICMP, obwohl HTTP(S) funktioniert.
net_ok() {
    curl -sf -o /dev/null --connect-timeout 5 --max-time 10 \
        https://cache.nixos.org/nix-cache-info 2>/dev/null \
    && curl -sfI -o /dev/null --connect-timeout 5 --max-time 10 \
        https://github.com 2>/dev/null
}

# Wartet auf DHCP. LAN-Kabel steckt bei den meisten Installationen bereits,
# dann ist der erste Versuch erfolgreich.
net_wait() {
    local i=1
    while [ "$i" -le 6 ]; do
        if net_ok; then
            return 0
        fi
        if [ "$i" -lt 6 ]; then
            info "Noch kein Netz – warte auf DHCP... (${i}/6)"
            sleep 3
        fi
        i=$((i + 1))
    done
    return 1
}

# --- SCHRITT 0: Netzwerk & Installations-DNS ---
info "Setze DNS für die Installation..."
set_install_dns

info "Prüfe Netzwerkverbindung (DHCP)..."
if ! net_wait; then
    # Manche Netze (Gast-WLAN, Captive Portal) erlauben nur den Router-DNS.
    # Dann lieber mit diesem weiterarbeiten als die Installation abzubrechen.
    if [ "${DNS_ACTIVE}" -eq 1 ]; then
        warn "Über ${INSTALL_DNS[*]} nicht erreichbar – teste den Router-DNS..."
        cleanup_install_dns
        if net_wait; then
            warn "Netz erlaubt nur den Router-DNS. Installation läuft damit weiter."
        fi
    fi
fi

if ! net_ok; then
    error "Keine Internetverbindung. LAN: Kabel prüfen (DHCP startet automatisch). WLAN: 'nmtui' starten und verbinden. Danach Skript erneut starten."
fi
info "Netzwerk OK."

# --- SCHRITT 0b: UEFI-Check ---
# Alle Hosts nutzen systemd-boot mit `canTouchEfiVariables = true`. Wird die ISO
# im Legacy/CSM-Modus gebootet, landet der Bootloader zwar auf der ESP, aber es
# entsteht KEIN NVRAM-Eintrag -> nach dem Reboot "no bootable device".
# Lieber hier abbrechen als die Platte zu löschen und dann ohne Boot dazustehen.
if [ ! -d /sys/firmware/efi ]; then
    warn "System wurde im Legacy/BIOS-Modus gebootet (kein /sys/firmware/efi)."
    warn "Alle Hosts verwenden systemd-boot (UEFI) – die Installation wäre nicht bootfähig."
    warn "Abhilfe: im BIOS/UEFI CSM bzw. Legacy-Boot deaktivieren,"
    warn "beim Booten den UEFI-Eintrag des USB-Sticks wählen, Skript erneut starten."
    error "Installation abgebrochen (Legacy-Boot)."
fi
info "UEFI-Modus erkannt."

# --- SCHRITT 1: Host-Auswahl ---
echo "=========================================================="
echo "  Mortiferus NixOS Multi-Host Installer"
echo "=========================================================="
echo ""
echo "Welches System soll installiert werden?"
echo "  1) nex (Haupt-PC / mortiferus)"
echo "  2) styx (Office-PC / backbone)"
echo "  3) test (QEMU-Test / test)"
echo "  4) lion-pc (Gaming-PC / lion)"
echo "  5) benny (Kumpel-PC / benny)"
echo ""
read -p "Auswahl [1-5]: " HOST_CHOICE

if [[ "$HOST_CHOICE" == "1" ]]; then
    HOSTNAME="nex"
    USERNAME="mortiferus"
elif [[ "$HOST_CHOICE" == "2" ]]; then
    HOSTNAME="styx"
    USERNAME="backbone"
elif [[ "$HOST_CHOICE" == "3" ]]; then
    HOSTNAME="test"
    USERNAME="test"
elif [[ "$HOST_CHOICE" == "4" ]]; then
    HOSTNAME="lion-pc"
    USERNAME="lion"
elif [[ "$HOST_CHOICE" == "5" ]]; then
    HOSTNAME="benny"
    USERNAME="benny"
else
    error "Ungültige Auswahl."
fi

info "Installiere Host: $HOSTNAME für User: $USERNAME"

# --- SCHRITT 1b: Laufwerksauswahl (SICHERHEIT) ---
# Problem: Linux erkennt Laufwerke nicht immer in gleicher Reihenfolge
# (nvme0 vs. nvme1 vs. sda vs. vda). Daher NIE hart verdrahten, sondern
# immer interaktiv anhand von Modell + Seriennummer + Label auswählen!
echo ""
echo "=========================================================="
echo "  Laufwerksauswahl"
echo "=========================================================="
echo ""
echo "Erkannte Laufwerke:"
echo "----------------------------------------------------------"

# NVMe, SATA/SAS/USB (sd*), VirtIO (vd*), IDE (hd*), eMMC (mmcblk*)
# lsblk -P gibt KEY="value"-Paare aus (Leerzeichen in Werten sind quoted).
# Hier ohne Python/JQ parsen, weil die ISO die nicht mitbringt.
INSTALL_DEVICES=()
while IFS= read -r line; do
    [ -z "$line" ] && continue
    # shellcheck disable=SC2046
    eval $(echo "$line" | grep -oE 'NAME="[^"]*"|SIZE="[^"]*"|MODEL="[^"]*"|SERIAL="[^"]*"|LABEL="[^"]*"|TYPE="[^"]*"')
    if [ "${TYPE}" = "disk" ] && [[ "$NAME" =~ ^(nvme|sd|vd|hd|mmcblk) ]]; then
        # 0-Byte-Geraete (leere Kartenleser, leere USB-Ports, toter Datentraeger)
        # NICHT anbieten: sgdisk bricht dort mit "0 sectors" ab.
        if [ "${SIZE}" = "0B" ] || [ -z "${SIZE}" ]; then
            warn "Ueberspringe ${NAME} (Groesse ${SIZE:-?}) – kein echtes/erreichbares Laufwerk."
            continue
        fi
        # Das laufende Live-Medium (USB-Installationsstick) ist gemountet und darf
        # NIE Ziel sein -> ausschliessen.
        if lsblk -n -o MOUNTPOINT "/dev/${NAME}" 2>/dev/null | grep -q '[^[:space:]]'; then
            warn "Ueberspringe ${NAME} (gemountet – laufendes Live-Medium)."
            continue
        fi
        INSTALL_DEVICES+=("${NAME}|${SIZE}|${MODEL}|${SERIAL}|${LABEL}")
    fi
done < <(lsblk -d -P -o NAME,SIZE,MODEL,SERIAL,LABEL,TYPE)

if [ ${#INSTALL_DEVICES[@]} -eq 0 ]; then
    echo ""
    warn "Keine installierbaren Laufwerke gefunden!"
    echo "----------------------------------------------------------"
    echo "Alle erkannten Blockgeräte:"
    lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,FSTYPE,MOUNTPOINTS 2>/dev/null || lsblk
    echo "----------------------------------------------------------"
    echo "Kernel-Meldungen zu SATA/USB (letzte Zeilen):"
    dmesg 2>/dev/null | grep -iE 'ata[0-9]|scsi|sd [a-z]|usb-storage|I/O error|failed' | tail -n 15 || true
    echo "----------------------------------------------------------"
    error "Erscheint die interne Platte hier mit SIZE=0 (oder fehlt ganz), dann: SATA-Kabel/Strom prüfen, im BIOS SATA auf AHCI statt RAID stellen, ggf. Datenträger tauschen. SIZE=0 trotz korrekter Verkabelung = Platte sehr wahrscheinlich defekt."
fi

for i in "${!INSTALL_DEVICES[@]}"; do
    echo "  [$((i+1))] ${INSTALL_DEVICES[$i]}"
done
echo "----------------------------------------------------------"
echo ""
read -p "Welches Laufwerk soll installiert werden? [1-${#INSTALL_DEVICES[@]}]: " DISK_CHOICE

if ! [[ "$DISK_CHOICE" =~ ^[0-9]+$ ]] || [ "$DISK_CHOICE" -lt 1 ] || [ "$DISK_CHOICE" -gt "${#INSTALL_DEVICES[@]}" ]; then
    error "Ungültige Auswahl."
fi

DISK_NAME=$(echo "${INSTALL_DEVICES[$((DISK_CHOICE-1))]}" | cut -d'|' -f1)
DISK_SIZE=$(echo "${INSTALL_DEVICES[$((DISK_CHOICE-1))]}" | cut -d'|' -f2)
DISK_MODEL=$(echo "${INSTALL_DEVICES[$((DISK_CHOICE-1))]}" | cut -d'|' -f3)
DISK_SERIAL=$(echo "${INSTALL_DEVICES[$((DISK_CHOICE-1))]}" | cut -d'|' -f4)
DISK_LABEL=$(echo "${INSTALL_DEVICES[$((DISK_CHOICE-1))]}" | cut -d'|' -f5)
DISK_DEVICE="/dev/${DISK_NAME}"

# Sanity-Check: Kernel muss eine echte Groesse kennen. Meldet das Geraet 0
# (defekt, falsch angeschlossen, BIOS/RAID-Modus), hier sauber abbrechen statt
# spaeter mit "Disk is too small to hold GPT data (0 sectors)" zu crashen.
DISK_SIZE_BYTES=$(sudo blockdev --getsize64 "$DISK_DEVICE" 2>/dev/null || echo 0)
if [ "${DISK_SIZE_BYTES:-0}" -lt 1073741824 ]; then
    error "Laufwerk ${DISK_DEVICE} meldet nur ${DISK_SIZE_BYTES} Bytes (0 = Kernel sieht keine Groesse). Mögliche Ursachen: Datenträger defekt, falsches Gerät gewählt, USB-/Kartenleser ohne Medium, oder SATA im BIOS auf RAID statt AHCI. Installation abgebrochen."
fi
info "Laufwerksgroesse: $(numfmt --to=iec "$DISK_SIZE_BYTES" 2>/dev/null || echo "${DISK_SIZE_BYTES}B")"

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
    # Optionen (--dns ...) beim Re-Exec mitnehmen.
    exec nix-shell -p git --run "$(printf '%q ' "$(readlink -f "$0")" "$@")"
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

# Partitionen des Ziel-Laufwerks EINZELN lösen. `umount -R /mnt` reicht nicht,
# wenn eine alte ESP/root noch an anderer Stelle gemountet ist (z. B. /boot oder
# /media/...). Eine gemountete Partition kann disko NICHT formatieren -> die
# alte Partitionstabelle und die alten Daten bleiben bestehen, und Altlasten
# werden mit der neuen Installation vermischt.
while read -r mnt; do
    [ -n "$mnt" ] && sudo umount "$mnt" 2>/dev/null || true
done < <(lsblk -rno MOUNTPOINT "$DISK_DEVICE" 2>/dev/null)

# Alte/ungueltige Partitionstabellen vorab entfernen. Verhindert, dass sgdisk
# bei einem Hybrid-MBR/GPT ("Found invalid GPT and valid MBR") die Umwandlung
# verweigert. Erste + letzte 16 MiB nullen (GPT-Backup sitzt am Disk-Ende).
#
# WICHTIG, Reihenfolge! Erst die Dateisystem-Signaturen der ALTEN Partitionen
# löschen, DANN die Partitionstabelle. disko formatiert eine Partition nur,
# wenn `blkid` KEIN vorhandenes Dateisystem meldet (idempotent). Löscht man
# zuerst die Partitionstabelle, verschwinden die alten /dev/sdXN-Geräte, disko
# kann deren Superblocks nicht mehr entfernen, und `mkfs` wird beim Neuanlegen
# STILL übersprungen -> alte Daten/ESP-Einträge bleiben "darunter" bestehen.
info "Bereinige alte Partitionen und Partitionstabelle auf ${DISK_DEVICE}..."
for part in $(lsblk -rno NAME "$DISK_DEVICE" 2>/dev/null | tail -n +2); do
    sudo wipefs -a -f "/dev/$part" 2>/dev/null || true
done
sudo wipefs -a -f "$DISK_DEVICE" 2>/dev/null || true
sudo dd if=/dev/zero of="$DISK_DEVICE" bs=1M count=16 status=none conv=fsync 2>/dev/null || true
DISK_END_MB=$(( DISK_SIZE_BYTES / 1048576 - 16 ))
if [ "$DISK_END_MB" -gt 16 ]; then
    sudo dd if=/dev/zero of="$DISK_DEVICE" bs=1M count=16 seek="$DISK_END_MB" status=none conv=fsync 2>/dev/null || true
fi
sudo blockdev --rereadpt "$DISK_DEVICE" 2>/dev/null || true

# UEFI-Eintraege liegen im NVRAM des Mainboards, nicht auf der Platte. Wipe und
# Neuinstallation loeschen sie NICHT -> sonst sammeln sich bei jeder Installation
# neue "NixOS"/"Linux Boot Manager"-Eintraege an. Hier alle entfernen; der
# Bootloader legt danach genau einen neuen an. Andere Systeme bleiben unangetastet.
if [ -d /sys/firmware/efi ] && command -v efibootmgr >/dev/null 2>&1; then
    info "Entferne alte NixOS-UEFI-Eintraege..."
    sudo efibootmgr 2>/dev/null \
        | sed -n -E 's/^Boot([0-9A-Fa-f]{4})\*? +(NixOS|Linux Boot Manager).*/\1/p' \
        | while read -r entry; do
            sudo efibootmgr -b "$entry" -B >/dev/null 2>&1 || warn "Konnte UEFI-Eintrag Boot${entry} nicht entfernen."
        done
fi

if [[ "$HOSTNAME" == "nex" ]]; then
    DISKO_CONFIG="${PWD}/hosts/nex/disk-config.nix"
elif [[ "$HOSTNAME" == "styx" ]]; then
    DISKO_CONFIG="${PWD}/modules/system/disko-basic.nix"
elif [[ "$HOSTNAME" == "test" ]]; then
    DISKO_CONFIG="${PWD}/hosts/test/disk-config.nix"
elif [[ "$HOSTNAME" == "lion-pc" ]]; then
    DISKO_CONFIG="${PWD}/hosts/lion-pc/disk-config.nix"
elif [[ "$HOSTNAME" == "benny" ]]; then
    DISKO_CONFIG="${PWD}/hosts/benny/disk-config.nix"
fi

# Temporaere disko-Config mit dem gewaehlten Device erzeugen.
# Das ist zuverlaessiger als --argstr device bei Flakes (wird ignoriert).
TEMP_DISKO_CONFIG="/tmp/disko-${HOSTNAME}.nix"
cat > "$TEMP_DISKO_CONFIG" <<EOF
(import ${DISKO_CONFIG} { device = "${DISK_DEVICE}"; })
EOF

info "Partitioniere und mounte ${DISK_DEVICE}..."

# `--yes-wipe-all-disks`: disko hat einen eigenen interaktiven Prompt
# ("Type 'yes' to continue"). Das Skript hat die Lösch-Bestätigung ("ja/NEIN")
# aber bereits abgefragt -> Doppel-Prompt vermeiden. Ohne den Schalter tippt
# man schnell "ja" statt "yes" und disko bricht ab, obwohl alles korrekt war.
sudo nix --experimental-features "nix-command flakes" \
    --option download-buffer-size 268435456 \
    --option connect-timeout 20 \
    run github:nix-community/disko -- \
    --mode destroy,format,mount \
    --yes-wipe-all-disks \
    "$TEMP_DISKO_CONFIG"

# --- FORMATIERUNGS-KONTROLLE ---
# Nach einer echten Formatierung enthält /mnt NUR lost+found (ext4) und die
# Mountpoint-Verzeichnisse weiterer Partitionen (hier "boot" für die ESP).
# Alles andere ist ein Altlast aus einer nicht sauber formatierten Platte
# (Partition noch gemountet, disko übersprungen, falsches Laufwerk). Dann
# lieber laut abbrechen als Altlasten mit dem neuen System zu vermischen.
# Die Mountpoint-Verzeichnisse werden aus findmnt abgeleitet, damit die Prüfung
# bei Hosts mit /home-/var-Partitionen nicht fälschlich anschlägt. lost+found
# ist immer dabei, damit die Filter-Liste nie leer ist.
legit_dirs="lost+found
$(findmnt -rno TARGET --submounts /mnt 2>/dev/null | sed -n 's#^/mnt/\([^/]*\).*#\1#p' | sort -u)"
root_leftover=$(sudo ls -A /mnt 2>/dev/null \
    | grep -vFxf <(printf '%s\n' "$legit_dirs") \
    | head -n1)
[ -z "$root_leftover" ] || error "Platte wurde NICHT sauber formatiert: /mnt enthält noch '${root_leftover}' (Altlasten). Bitte erneut starten – tritt es wieder auf, Platte prüfen/tauschen."

if mountpoint -q /mnt/boot; then
    boot_leftover=$(sudo ls -A /mnt/boot 2>/dev/null | head -n1)
    [ -z "$boot_leftover" ] || error "ESP wurde NICHT sauber formatiert: /mnt/boot enthält noch '${boot_leftover}' (alte Boot-Einträge). Abbruch."
fi

# --- TEMPORÄRER SWAP GEGEN OOM (nur für die Installation) ---
# Die disko-Configs haben KEINEN dauerhaften Swap (System läuft ZRAM-only).
# Für den nixos-install-Build kann viel RAM nötig sein (OOM-Risiko).
# Daher legen wir hier ein temporäres Swapfile auf /mnt an, aktivieren es
# für die Installation und entfernen es danach wieder — es landet also
# NIE im installierten System. (SWAPFILE + cleanup_swap stehen oben, damit
# der EXIT-Trap auch DNS und Swap gemeinsam aufräumt.)

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
    # Vollständig reservieren: truncate erzeugt eine sparse Datei, und swapon
    # lehnt Dateien mit Löchern ab ("swapfile has holes") -> es wurde nie Swap aktiv.
    sudo touch "$SWAPFILE"
    sudo chmod 600 "$SWAPFILE"
    if ! sudo fallocate -l "${swap_mb}M" "$SWAPFILE" 2>/dev/null; then
        sudo dd if=/dev/zero of="$SWAPFILE" bs=1M count="$swap_mb" status=none
    fi
    sudo mkswap "$SWAPFILE" >/dev/null
    sudo swapon "$SWAPFILE" && info "Swap aktiv (${swap_mb}MB)." \
        || { warn "Swapfile konnte nicht aktiviert werden — weiter ohne Swap (OOM-Risiko)"; sudo rm -f "$SWAPFILE"; }
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
# .git des Clones MITKOPIEREN (nicht entfernen!): so hat das Ziel-Repo sofort
# `origin/main` als Remote-Tracking-Ref und `main` trackt `origin/main`.
# Nur dadurch funktionieren `git pull` und `nix-sync`
# (`git reset --hard origin/main && git pull`) direkt nach der Installation.
sudo cp -r . /mnt/etc/nixos/

# --- SCHRITT 6: Installation ---
info "Starte NixOS-Installation für $HOSTNAME..."
# Extra-Substituter: holt Prebuilds (nix-community, noctalia, umbriel) statt
# lokal zu bauen; cache.nixos.org ist immer dabei. Muss zu
# modules/system/nix-settings.nix passen.
# WICHTIG: Die substituters aus der Ziel-Config greifen beim Install NICHT –
# nixos-install baut mit der nix.conf des Live-Systems. Fehlt hier ein Cache,
# wird das Paket (z. B. umbriel mit scenefx/wlroots) lokal kompiliert.
sudo nixos-install --flake "/mnt/etc/nixos#$HOSTNAME" \
    --option max-jobs "$MAX_JOBS" \
    --option cores "$CORES" \
    --option download-buffer-size 268435456 \
    --option connect-timeout 20 \
    --option extra-substituters 'https://nix-community.cachix.org https://noctalia.cachix.org https://umbriel.cachix.org' \
    --option extra-trusted-public-keys 'nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4= umbriel.cachix.org-1:JfNq/2yg2S6D6z4Z2dVSZrZlDPQTKtexB6GAVLD98nw=' \
    --no-root-passwd --no-channel-copy

# --- WLAN-VERBINDUNGEN VOM LIVE-SYSTEM ÜBERNEHMEN ---
# Die Verzeichnisse gehören root (Modus 700). Das Skript läuft als normaler User,
# daher alle Lesezugriffe über sudo. Vorher hat ein `ls` ohne sudo still nichts
# gefunden -> WLAN wurde nie übernommen.
# Zwei Quellen: NetworkManager (*.nmconnection) und iwd (/var/lib/iwd, falls
# per iwctl verbunden wurde). nex nutzt NM mit iwd-Backend, legt also beides ab.
info "Kopiere WLAN-Verbindungen vom Live-System..."
WLAN_COUNT=0

NM_SRC=/etc/NetworkManager/system-connections
if sudo test -d "$NM_SRC"; then
    NM_FILES=$(sudo sh -c "ls $NM_SRC/*.nmconnection 2>/dev/null" || true)
    if [ -n "$NM_FILES" ]; then
        sudo mkdir -p /mnt/etc/NetworkManager/system-connections
        for f in $NM_FILES; do
            sudo cp "$f" /mnt/etc/NetworkManager/system-connections/
            WLAN_COUNT=$((WLAN_COUNT + 1))
        done
        sudo chown -R root:root /mnt/etc/NetworkManager/system-connections/
        sudo chmod 700 /mnt/etc/NetworkManager/system-connections
        sudo chmod 600 /mnt/etc/NetworkManager/system-connections/*.nmconnection 2>/dev/null || true
    fi
fi

IWD_SRC=/var/lib/iwd
if sudo test -d "$IWD_SRC"; then
    IWD_FILES=$(sudo sh -c "ls $IWD_SRC/*.psk $IWD_SRC/*.open $IWD_SRC/*.8021x 2>/dev/null" || true)
    if [ -n "$IWD_FILES" ]; then
        sudo mkdir -p /mnt/var/lib/iwd
        for f in $IWD_FILES; do
            sudo cp "$f" /mnt/var/lib/iwd/
            WLAN_COUNT=$((WLAN_COUNT + 1))
        done
        sudo chown -R root:root /mnt/var/lib/iwd
        sudo chmod 700 /mnt/var/lib/iwd
        sudo chmod 600 /mnt/var/lib/iwd/* 2>/dev/null || true
    fi
fi

if [ "${WLAN_COUNT}" -gt 0 ]; then
    info "WLAN-Profile übernommen: ${WLAN_COUNT}"
else
    # Kein Fehler: bei LAN-Installation (DHCP) gibt es nichts zu übernehmen.
    info "Keine WLAN-Profile vorhanden (LAN-Installation) – nichts zu übernehmen."
fi

# --- SCHRITT 6b: Verifikation (Aufruf erfolgt nach Rechte/Passwoerter) ---
# Lieber laut abbrechen als in ein nicht bootfaehiges System rebooten.
# Prueft die Stellen, die typischerweise "Installation lief durch, bootet aber
# nicht" verursachen: unvollstaendiger Store, fehlende Kern-Binaries,
# Partlabels aus /etc/fstab, Bootloader auf der ESP, freier Platz, Rechte.
# Wird bewusst erst nach chown/passwd aufgerufen: bricht die Verifikation ab,
# ist das System trotzdem vollstaendig eingerichtet und benutzbar.
verify_installation() {
info "Verifiziere die Installation..."
VERIFY_FAIL=0
verify_fail() {
    warn "$1"
    VERIFY_FAIL=$((VERIFY_FAIL + 1))
}

store_count=$(sudo find /mnt/nix/store -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
info "Store-Pfade: ${store_count}"
[ "${store_count}" -gt 1500 ] || verify_fail "Store wirkt unvollstaendig (nur ${store_count} Pfade)."

live_dns=$(grep -h '^nameserver' /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ' ' || true)
info "DNS der Live-Sitzung: ${live_dns:-unbekannt}"

sudo sh -c 'ls /mnt/nix/store/*-systemd-*/lib/systemd/systemd-udevd >/dev/null 2>&1' \
    || verify_fail "systemd-udevd fehlt im Store."
sudo sh -c 'ls /mnt/nix/store/*-systemd-*/lib/systemd/systemd-journald >/dev/null 2>&1' \
    || verify_fail "systemd-journald fehlt im Store."

fstab_labels=$(sudo awk '$1 ~ /^\/dev\/disk\/by-partlabel\// {sub(".*/", "", $1); print $1}' /mnt/etc/fstab 2>/dev/null | sort -u)
for label in $fstab_labels; do
    if ! sudo blkid -t "PARTLABEL=${label}" -o device 2>/dev/null | grep -q .; then
        verify_fail "Partlabel '${label}' aus /etc/fstab existiert nicht auf der Platte."
    fi
done

mountpoint -q /mnt/boot || verify_fail "/boot ist nicht gemountet."
sudo test -f /mnt/boot/EFI/systemd/systemd-bootx64.efi \
    || verify_fail "systemd-boot (systemd-bootx64.efi) fehlt auf der ESP."
sudo sh -c 'ls /mnt/boot/loader/entries/*.conf >/dev/null 2>&1' \
    || verify_fail "Keine Boot-Eintraege auf der ESP (/boot/loader/entries)."

avail_mb=$(sudo df -Pm /mnt 2>/dev/null | awk 'NR==2 {print $4}')
[ "${avail_mb:-0}" -gt 1024 ] || verify_fail "Wenig Platz auf / (${avail_mb:-?} MB frei)."

# Rechte: Home des Users muss existieren und ihm gehoeren.
# WICHTIG: numerisch vergleichen. `stat -c %U` loest den Namen ueber die
# /etc/passwd des LIVE-Systems auf (UID 1000 = nixos) und wuerde eine
# korrekte Installation faelschlich als fehlerhaft melden.
if ! sudo test -d "/mnt/home/$USERNAME"; then
    info "Lege /home/$USERNAME im Zielsystem an (fehlte nach nixos-install)..."
    sudo nixos-enter --root /mnt -c "install -d -m 700 -o $USERNAME -g users /home/$USERNAME" \
        || verify_fail "Konnte /home/$USERNAME nicht anlegen."
fi

target_uid=$(sudo awk -F: -v u="$USERNAME" '$1 == u {print $3}' /mnt/etc/passwd 2>/dev/null || true)
target_gid=$(sudo awk -F: -v u="$USERNAME" '$1 == u {print $4}' /mnt/etc/passwd 2>/dev/null || true)
home_uid=$(sudo stat -c '%u' "/mnt/home/$USERNAME" 2>/dev/null || echo "fehlt")
home_gid=$(sudo stat -c '%g' "/mnt/home/$USERNAME" 2>/dev/null || echo "fehlt")

if [ -z "$target_uid" ]; then
    verify_fail "Benutzer $USERNAME fehlt in /mnt/etc/passwd."
elif [ "$home_uid" != "$target_uid" ]; then
    verify_fail "/home/$USERNAME gehoert UID $home_uid, erwartet $target_uid ($USERNAME)."
elif [ -n "$target_gid" ] && [ "$home_gid" != "$target_gid" ]; then
    verify_fail "/home/$USERNAME gehoert GID $home_gid, erwartet $target_gid."
fi

for f in /mnt/etc/NetworkManager/system-connections/*.nmconnection /mnt/var/lib/iwd/*; do
    [ -e "$f" ] || continue
    mode=$(sudo stat -c '%a' "$f" 2>/dev/null)
    [ "$mode" = "600" ] || verify_fail "WLAN-Datei $(basename "$f") hat Modus $mode statt 600."
done

if [ "${VERIFY_FAIL}" -ne 0 ]; then
    echo ""
    warn "=========================================================="
    warn "  VERIFIKATION FEHLGESCHLAGEN (${VERIFY_FAIL} Punkt(e))"
    warn "  NICHT REBOOTEN - bitte ein Foto dieses Bildschirms schicken."
    warn "=========================================================="
    error "Installation unvollstaendig - Abbruch vor dem Reboot."
fi
info "Verifikation OK - System ist bootfaehig."
}

# --- SCHRITT 7: Rechte & Git-Setup ---
info "Bereite Zielsystem vor (Rechte & Git)..."

# Remote-URL pro Host: nex pusht via SSH, alle anderen Pull-Hosts via HTTPS.
REMOTE_URL="https://github.com/xXMortiferusXx/nix-config.git"
if [[ "$HOSTNAME" == "nex" ]]; then
    REMOTE_URL="git@github.com:xXMortiferusXx/nix-config.git"
fi

# Das .git stammt vom Clone (siehe SCHRITT 5) und gehoert noch root -> jetzt
# als root die Remote-URL setzen (vermeidet git "dubious ownership"). `main`
# trackt bereits `origin/main`, `origin/main` existiert als Remote-Tracking-Ref.
sudo nixos-enter --root /mnt -c "cd /etc/nixos && git remote set-url origin $REMOTE_URL"

# Erst JETZT Rechte setzen (inkl. .git), damit der User pullen/committen kann.
# (nixos-enter läuft als root -> .git gehörte sonst root und `git pull` schlägt
# mit "Permission denied" auf .git fehl.)
sudo nixos-enter --root /mnt -c "chown -R $USERNAME:users /etc/nixos"

# Gegenprobe (Name wird hier im Zielsystem aufgelöst, nicht im Live-System).
repo_owner=$(sudo nixos-enter --root /mnt -c "stat -c %U /etc/nixos" 2>/dev/null || echo "unbekannt")
if [ "$repo_owner" = "$USERNAME" ]; then
    info "Rechte OK: /etc/nixos gehoert $USERNAME."
else
    warn "/etc/nixos gehoert ${repo_owner} statt ${USERNAME} – git pull als $USERNAME wird fehlschlagen."
fi

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
# Erst jetzt pruefen: Rechte und Passwoerter sind gesetzt, das System ist
# selbst bei einem Verifikationsfehler vollstaendig eingerichtet.
verify_installation

echo ""
echo "=========================================================="
echo "  INSTALLATION VON $HOSTNAME ABGESCHLOSSEN!"
echo "=========================================================="
echo ""
echo "Nächste Schritte nach dem Reboot:"
echo "  1. Einloggen als $USERNAME"
if [[ "$REMOTE_URL" == https://* ]]; then
    echo "  2. Config liegt unter /etc/nixos als Git-Repo (HTTPS); Branch main folgt origin/main"
    echo "     → Updates mit:  nix-sync   (git reset --hard origin/main && git pull && rebuild)"
else
    echo "  2. SSH-Key erstellen und bei GitHub hinterlegen (Repo unter /etc/nixos, main folgt origin/main)"
    echo "     → Updates mit:  nix-sync"
fi
echo "  3. nixos-rebuild (falls nötig) und los geht's"
echo ""
echo "Du kannst jetzt 'reboot' tippen."
echo "=========================================================="
