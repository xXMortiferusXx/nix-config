#!/usr/bin/env bash
set -euo pipefail

# QEMU-VM fuer Installer-Testing
# Erstellt 2 virtuelle NVMe-Disks und bootet NixOS ISO.
# Damit kann der komplette Installer-Flow getestet werden.

# --- KONFIGURATION ---
VM_NAME="nixos-test"
DISK_SIZE="20G"
RAM="4G"
CPUS="2"
SSH_PORT="2222"
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
    echo "Usage: $0 [iso|vm|clean]"
    echo ""
    echo "  iso   - Baut NixOS ISO und bootet mit 2 NVMe Disks (Installer-Test)"
    echo "  vm    - Baut und bootet den Test-Host direkt (Config-Test)"
    echo "  clean - Loescht alle temporaeren QEMU-Dateien (${VM_DIR})"
    echo ""
    exit 1
}

case "$MODE" in
    iso) ;;
    vm)  ;;
    clean)
        if [ -d "$VM_DIR" ]; then
            info "Loesche ${VM_DIR}..."
            rm -rf "$VM_DIR"
            info "Aufgeraeumt."
        else
            info "Nichts aufzuraeumen (${VM_DIR} existiert nicht)."
        fi
        exit 0
        ;;
    *)   usage ;;
esac

# OVMF Firmware finden (UEFI)
info "Suche OVMF Firmware..."
OVMF_CODE=$(find /nix/store -path "*/FV/OVMF_CODE.fd" -type f 2>/dev/null | head -1 || true)
OVMF_VARS=$(find /nix/store -path "*/FV/OVMF_VARS.fd" -type f 2>/dev/null | head -1 || true)

if [ -z "$OVMF_CODE" ]; then
    error "OVMF_CODE.fd nicht gefunden."
fi
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
    # --- ISO-Modus: NixOS ISO bauen und booten ---
    ISO_CACHE="${VM_DIR}/iso-path"

    if [ -f "$ISO_CACHE" ] && [ -f "$(cat "$ISO_CACHE" 2>/dev/null)" ]; then
        ISO_PATH=$(cat "$ISO_CACHE")
        info "ISO aus Cache: $ISO_PATH"
    else
        info "Baue NixOS minimal ISO (flakes + git + curl)..."
        ISO_RESULT=$(cd /etc/nixos && nix build .#installer-iso --no-link --print-out-paths 2>&1 | tail -1)

        if [ -z "$ISO_RESULT" ] || [ ! -d "$ISO_RESULT" ]; then
            error "ISO-Build fehlgeschlagen: $ISO_RESULT"
        fi

        ISO_PATH=$(find "$ISO_RESULT" -name "*.iso" -type f 2>/dev/null | head -1 || true)

        if [ -z "$ISO_PATH" ] || [ ! -f "$ISO_PATH" ]; then
            error "ISO-Datei nicht im Build-Ergebnis gefunden: $ISO_RESULT"
        fi

        echo "$ISO_PATH" > "$ISO_CACHE"
        info "ISO gebaut: $ISO_PATH"
    fi

        if [ -z "$ISO_PATH" ] || [ ! -f "$ISO_PATH" ]; then
            error "ISO-Build fehlgeschlagen."
        fi

        echo "$ISO_PATH" > "$ISO_CACHE"
        info "ISO gebaut: $ISO_PATH"
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
    info "Inside VM: install.sh starten fuer vollstaendigen Installer-Test"
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
