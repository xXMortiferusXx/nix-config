#!/usr/bin/env bash
set -euo pipefail

# QEMU-VM fuer Installer-Testing
# Erstellt 2 virtuelle NVMe-Disks und bootet NixOS ISO.
# Damit kann der komplette Installer-Flow getestet werden.

# --- KONFIGURATION ---
VM_NAME="nixos-test"
# Pro virtuelle NVMe. Die Images sind sparse (truncate) - auf der Platte landet
# nur, was wirklich geschrieben wird. 20G waren fuer eine volle Desktop-
# Installation (KDE, flatpak-Basis, Home-Manager) zu knapp.
DISK_SIZE="${DISK_SIZE:-80G}"
RAM="${RAM:-4G}"
CPUS="${CPUS:-2}"
SSH_PORT="${SSH_PORT:-2222}"
VM_DIR="/tmp/${VM_NAME}"
# ---------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- QEMU-Optionen ---
MODE="${1:-iso}"

usage() {
    echo "Usage: $0 [iso [ISO-DATEI] | vm | clean]"
    echo ""
    echo "  iso [ISO-DATEI] - bootet die Installer-ISO mit 2 NVMe Disks"
    echo "                    ohne Pfad: nimmt/aktualisiert die ISO aus dem Flake"
    echo "                    mit Pfad:  bootet genau diese Datei"
    echo "  vm    - Baut und bootet den Test-Host direkt (Config-Test)"
    echo "  clean - Loescht alle temporaeren QEMU-Dateien (${VM_DIR})"
    echo ""
    echo "  Disk-Groesse pro NVMe: ${DISK_SIZE}  (DISK_SIZE=120G $0 iso)"
    echo "  Nach Aenderung der Groesse einmal '$0 clean' - bestehende Images"
    echo "  werden NICHT vergroessert."
    echo ""
    exit 1
}

case "$MODE" in
    iso) ;;
    vm)  ;;
    clean)
        if [ -d "$VM_DIR" ]; then
            FREED=$(du -sh "$VM_DIR" 2>/dev/null | cut -f1)
            info "Loesche ${VM_DIR} (${FREED:-?} auf der Platte belegt)..."
            rm -rf "$VM_DIR"
            info "Aufgeraeumt. Entfernt wurden: NVMe-Images, OVMF_VARS-Kopie"
            info "und der alte ISO-Pfad-Cache. Das ISO selbst liegt im"
            info "Nix-Store und wird von der Nix-GC (nix-gc.timer) aufgeraeumt."
        else
            info "Nichts aufzuraeumen (${VM_DIR} existiert nicht)."
        fi
        exit 0
        ;;
    *)   usage ;;
esac

# OVMF Firmware finden (UEFI). Fehlt sie im Store, aus nixpkgs holen -
# sonst scheitert der ISO-Test, obwohl qemu selbst per nix nachgeladen wird.
info "Suche OVMF Firmware..."
OVMF_CODE=$(find /nix/store -maxdepth 3 -path "*/OVMF*/FV/OVMF_CODE.fd" -type f 2>/dev/null | head -1 || true)

if [ -z "$OVMF_CODE" ]; then
    info "OVMF nicht im Store - baue nixpkgs#OVMF.fd..."
    OVMF_STORE=$(cd /etc/nixos && nix build 'nixpkgs#OVMF.fd' --no-link --print-out-paths 2>/dev/null | tail -1 || true)
    if [ -n "$OVMF_STORE" ] && [ -f "${OVMF_STORE}/FV/OVMF_CODE.fd" ]; then
        OVMF_CODE="${OVMF_STORE}/FV/OVMF_CODE.fd"
    fi
fi

if [ -z "$OVMF_CODE" ]; then
    error "OVMF_CODE.fd nicht gefunden (auch nicht baubar)."
fi

# VARS immer aus demselben Paket wie CODE (Versions-Mismatch = kein Boot).
OVMF_VARS="$(dirname "$(dirname "$OVMF_CODE")")/FV/OVMF_VARS.fd"
[ -f "$OVMF_VARS" ] || OVMF_VARS=""
info "OVMF CODE: $OVMF_CODE"
[ -n "$OVMF_VARS" ] && info "OVMF VARS: $OVMF_VARS"

# QEMU finden (nicht immer im PATH)
if ! command -v qemu-system-x86_64 &>/dev/null; then
    QEMU_STORE=$(cd /etc/nixos && nix build nixpkgs#legacyPackages.x86_64-linux.qemu --no-link --print-out-paths 2>/dev/null | tail -1 || true)
    if [ -n "$QEMU_STORE" ] && [ -x "${QEMU_STORE}/bin/qemu-system-x86_64" ]; then
        export PATH="${QEMU_STORE}/bin:$PATH"
        info "QEMU via nix: qemu-system-x86_64"
    else
        error "qemu-system-x86_64 nicht gefunden. Installiere: nix profile install nixpkgs#qemu"
    fi
fi

# VM-Verzeichnis erstellen
mkdir -p "$VM_DIR"

# NVMe Disk-Images erstellen (falls nicht vorhanden)
DISK0="${VM_DIR}/nvme0.raw"
DISK1="${VM_DIR}/nvme1.raw"

if [ ! -f "$DISK0" ]; then
    info "Erstelle virtuelle NVMe Disk 0 (${DISK_SIZE})..."
    truncate -s "$DISK_SIZE" "$DISK0"
fi

if [ ! -f "$DISK1" ]; then
    info "Erstelle virtuelle NVMe Disk 1 (${DISK_SIZE})..."
    truncate -s "$DISK_SIZE" "$DISK1"
fi

# Bestehende Images NICHT automatisch vergroessern - das aendert nur die
# Dateigroesse, nicht die Partitionstabelle darin. Lieber deutlich sagen.
check_disk_size() {
    local f=$1 want have
    want=$(numfmt --from=iec "$DISK_SIZE" 2>/dev/null || echo 0)
    [ "$want" -gt 0 ] || return 0
    have=$(stat -c %s "$f")
    if [ "$have" -lt "$want" ]; then
        warn "$(basename "$f") ist nur $(numfmt --to=iec "$have") gross (gewuenscht ${DISK_SIZE})."
        warn "Bestehende Images werden nicht vergroessert - vorher '$0 clean' ausfuehren."
    fi
}
check_disk_size "$DISK0"
check_disk_size "$DISK1"

# QEMU-Basisargumente
QEMU_ARGS=(
    -enable-kvm
    -m "$RAM"
    -smp "$CPUS"
    -machine q35
    -drive "if=pflash,format=raw,readonly=on,file=${OVMF_CODE}"
    -netdev "user,id=net0,hostfwd=tcp::${SSH_PORT}-:22"
    -device "virtio-net-pci,netdev=net0"
)

# NVMe Disks hinzufuegen (als echte NVMe-Controller, nicht virtio-blk)
QEMU_ARGS+=(
    -drive "file=${DISK0},if=none,id=nvm0,format=raw"
    -device "nvme,serial=NVME00001,drive=nvm0"
    -drive "file=${DISK1},if=none,id=nvm1,format=raw"
    -device "nvme,serial=NVME00002,drive=nvm1"
)

if [ "$MODE" = "iso" ]; then
    # --- ISO-Modus: ISO booten (bauen nur, wenn nicht schon im Store) ---
    # Optional als 2. Argument: eine vorhandene ISO-Datei, z.B. das Ergebnis
    # eines eigenen `nix build .#installer-iso` (result/iso/*.iso).
    ISO_PATH="${2:-}"

    if [ -n "$ISO_PATH" ]; then
        [ -f "$ISO_PATH" ] || error "ISO-Datei nicht gefunden: $ISO_PATH"
        info "ISO (uebergeben): $ISO_PATH"
    else
        # Bewusst KEIN Pfad-Cache: `nix build` liefert bei unveraenderter
        # Konfiguration sofort denselben Store-Pfad (kein Neubau), nach einer
        # Aenderung aber garantiert die neue ISO. Ein Cache wuerde veralten.
        info "Ermittle Installer-ISO (baut nur bei Aenderungen)..."
        ISO_RESULT=$(cd /etc/nixos && nix build .#installer-iso --no-link --print-out-paths 2>&1 | tail -1)

        if [ -z "$ISO_RESULT" ] || [ ! -d "$ISO_RESULT" ]; then
            error "ISO-Build fehlgeschlagen: $ISO_RESULT"
        fi

        ISO_PATH=$(find "$ISO_RESULT" -name "*.iso" -type f 2>/dev/null | head -1 || true)

        if [ -z "$ISO_PATH" ] || [ ! -f "$ISO_PATH" ]; then
            error "ISO-Datei nicht im Build-Ergebnis gefunden: $ISO_RESULT"
        fi

        info "ISO: $ISO_PATH"
    fi

    QEMU_ARGS+=(-cdrom "$ISO_PATH")

    if [ -n "$OVMF_VARS" ]; then
        QEMU_ARGS+=(-drive "if=pflash,format=raw,file=${VM_DIR}/OVMF_VARS.fd")
        if [ ! -f "${VM_DIR}/OVMF_VARS.fd" ]; then
            cp "$OVMF_VARS" "${VM_DIR}/OVMF_VARS.fd"
            chmod 644 "${VM_DIR}/OVMF_VARS.fd"
        fi
    fi

    info "Starte QEMU (ISO-Modus)..."
    info "Inside VM: lsblk zeigt /dev/nvme0n1 + /dev/nvme1n1"
    info "Inside VM: install-nixos starten (holt install.sh, zeigt Version+SHA256)"
    info "SSH: ssh -p ${SSH_PORT} root@localhost (nach Install)"
    echo ""

    exec qemu-system-x86_64 "${QEMU_ARGS[@]}"

elif [ "$MODE" = "vm" ]; then
    # --- VM-Modus: Test-Host direkt bauen ---
    info "Baue Test-Host VM..."
    VM_RESULT=$(nix build .#nixosConfigurations.test.config.system.build.vm --no-link --print-out-paths 2>/dev/null)

    if [ -z "$VM_RESULT" ]; then
        error "VM-Build fehlgeschlagen."
    fi

    VM_SCRIPT=$(find "$VM_RESULT" -name "run-*-vm" -type f 2>/dev/null | head -1)

    if [ -z "$VM_SCRIPT" ]; then
        error "VM-Startskript nicht gefunden in $VM_RESULT"
    fi

    info "VM-Built: $VM_RESULT"
    info "Starte VM..."
    info "SSH: ssh -p ${SSH_PORT} root@localhost"
    echo ""

    exec "$VM_SCRIPT"
fi
