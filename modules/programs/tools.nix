# Zusatz-Tools und Fish-Aliase für System-/Nix-Pflege.
{ config, pkgs, ... }:
let
  # Reboot-Einschaetzung: vergleicht /run/booted-system mit einem Ziel-System
  # (Default /run/current-system, optional z.B. ./result vor dem Switch).
  nixRebootCheck = pkgs.writeShellScriptBin "nix-reboot-check" ''
    set -u
    target="''${1:-/run/current-system}"
    booted=/run/booted-system
    changed() { [ "$(readlink -f "$booted/$1" 2>/dev/null)" != "$(readlink -f "$target/$1" 2>/dev/null)" ]; }
    boot_kver=$(ls "$booted/kernel-modules/lib/modules/" 2>/dev/null | head -1)
    new_kver=$(ls "$target/kernel-modules/lib/modules/" 2>/dev/null | head -1)
    if [ -n "$boot_kver" ] && [ -n "$new_kver" ] && [ "$boot_kver" != "$new_kver" ]; then
      echo "REBOOT: JA (neuer Kernel: $boot_kver -> $new_kver)"
    elif changed kernel-modules; then
      echo "REBOOT: empfohlen (Kernel-Module geaendert - z.B. NVIDIA-Treiber)"
    elif changed kernel || changed initrd; then
      echo "REBOOT: empfohlen (Kernel/initrd neu gebaut, laufender Kernel unveraendert)"
    elif changed init; then
      echo "REBOOT: empfohlen (systemd/PID1 geaendert)"
    elif changed firmware; then
      echo "REBOOT: empfohlen (Firmware geaendert)"
    else
      echo "REBOOT: nein (nur Userspace)"
    fi
  '';

  # Host-agnostischer Update-Befehl, z.B. fuer den "Nix Monitor"-Button in Noctalia.
  # Kein hartkodiertes #hostname; gibt am Ende die Reboot-Einschaetzung aus.
  nixosUpdate = pkgs.writeShellScriptBin "nixos-update" ''
    set -u
    cd /etc/nixos || exit 1
    nix flake update
    sudo nixos-rebuild switch --flake ".#$(hostname)"
    nix-reboot-check
  '';

  # Zeigt Rate/Quantum/ERR der gerade laufenden Audio-Knoten (GC7-Praefix gekuerzt).
  # Nuetzlich, weil weder Player noch DAC die tatsaechlich ausgehandelte Rate anzeigen.
  audioRate = pkgs.writeShellScriptBin "audio-rate" ''
    set -u
    echo "Aktive Audio-Knoten (Rate / Quantum / ERR):"
    pw-top -b -n 2 2>/dev/null | awk '
      $2 == "ID" { snap = snap + 1; next }
      snap >= 2 && ($3 + 0) > 0 {
        name = "";
        for (i = 13; i <= NF; i++) name = name (i > 13 ? " " : "") $i;
        sub(/alsa_(output|input)\.usb-Creative_Technology_Ltd_Sound_Blaster_GC7_[A-Za-z0-9]+-03\./, "", name);
        printf "  %-32s %7s Hz  quantum %-5s  ERR %s\n", name, $4, $3, $9;
      }'
  '';

  # Update + Build testen, OHNE bei Fehlern einen kaputten flake.lock zu hinterlassen.
  # Erfolg: neuer Lock bleibt stehen. Fehler: alter Lock wird restauriert.
  nixCheck = pkgs.writeShellScriptBin "nix-check" ''
    set -u
    repo=/etc/nixos
    host=$(hostname)
    trace=""
    if [ "''${1:-}" = "--trace" ]; then trace="--show-trace"; fi

    backup=$(mktemp)
    trap 'rm -f "$backup"' EXIT
    cp "$repo/flake.lock" "$backup"

    np_path() { nix eval --impure --raw --expr '(builtins.getFlake "/etc/nixos").inputs.nixpkgs.outPath' 2>/dev/null || true; }
    old_np=$(np_path)

    echo "== nix flake update =="
    if ! (cd "$repo" && nix flake update); then
      cp "$backup" "$repo/flake.lock"
      echo "nix-check: flake update fehlgeschlagen - Lock unveraendert."
      exit 1
    fi

    # Ankuendigung, die nixpkgs bei unstable nicht liefert: was wurde neu entfernt/umbenannt?
    new_np=$(np_path)
    if [ -n "$old_np" ] && [ -n "$new_np" ] && [ "$old_np" != "$new_np" ] \
       && [ -f "$old_np/pkgs/top-level/aliases.nix" ] && [ -f "$new_np/pkgs/top-level/aliases.nix" ]; then
      echo
      echo "== nixpkgs: neu entfernt/umbenannt =="
      diff -U0 "$old_np/pkgs/top-level/aliases.nix" "$new_np/pkgs/top-level/aliases.nix" 2>/dev/null \
        | grep -E '^\+.*= *(throw|warnAlias)' \
        | sed 's/^+ *//' | head -25 || true
    fi

    echo "== nixos-rebuild build ($host) =="
    if ! (cd "$repo" && nixos-rebuild build --flake ".#$host" $trace); then
      cp "$backup" "$repo/flake.lock"
      echo
      echo "nix-check: BUILD FEHLGESCHLAGEN."
      echo "flake.lock wurde auf den letzten Stand zurueckgesetzt; das System bleibt unangetastet."
      echo "Vollstaendiger Trace:  nix-check --trace"
      exit 1
    fi

    echo
    echo "== Wichtige Paket-Aenderungen (direkt gewaehlt, nur Versionswechsel) =="
    diff_out=$(nvd diff -s /run/current-system "$repo/result" 2>/dev/null || true)
    ver_lines=$(printf '%s\n' "$diff_out" | grep -E '^\[(U|A|R)' || true)
    if [ -n "$ver_lines" ]; then
      printf '%s\n' "$ver_lines"
    else
      echo "(keine Versionswechsel)"
    fi
    rebuilds=$(printf '%s\n' "$diff_out" | grep -cE '^\[C' || true)
    if [ "''${rebuilds:-0}" -gt 0 ]; then
      echo "($rebuilds weitere Rebuilds ohne Versionswechsel)"
    fi

    echo
    ${nixRebootCheck}/bin/nix-reboot-check "$repo/result"
    echo
    echo "nix-check: OK - Lock behalten. Switch mit: nix-switch"
  '';
in
{
  environment.systemPackages = with pkgs; [
    iw
    jq
    ookla-speedtest
    scx.full
  ] ++ [ nixCheck nixRebootCheck nixosUpdate audioRate ];

  programs.fish.shellAliases = {

    # System & Update (hostname wird per Fish-Funktion dynamisch aufgelöst)
    nix-search = "nix search nixpkgs";
    # nix-check ist ein eigenes Skript (siehe nixCheck oben) - restauriert den Lock bei Fehlern.
    nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#(hostname) && nix-reboot-check";
    nix-update = "pushd /etc/nixos && nix flake update && sudo nixos-rebuild switch --flake .#(hostname) && popd";
    # Reparatur-Sync: Inputs mit aktualisieren, damit kein Downgrade auf einen
    # alten Lock passiert, wenn der letzte Push schon laenger her ist
    # (bewusste Entscheidung -- nicht entfernen).
    nix-sync   = "pushd /etc/nixos && git reset --hard origin/main && git pull && nix flake update && sudo nixos-rebuild switch --flake .#(hostname) && nix-reboot-check && popd";
    night-update = "umbriel msg dpms-off && pushd /etc/nixos && nix flake update && sudo systemd-inhibit --why='Nightly Update' --mode=block nixos-rebuild switch --flake .#(hostname); popd";

    nix-clean  = "sudo nix-collect-garbage -d && sudo nix-store --optimise && sudo nixos-rebuild switch --flake /etc/nixos#(hostname)";

    # Git ohne sudo, damit die SSH-Keys des Users genutzt werden.
    conf-sync  = "pushd /etc/nixos && git add . && git commit -m \"Update: $(date +'%Y-%m-%d %H:%M')\" && git push origin main; popd";
    conf       = "cd /etc/nixos";

     scx-status = "scxtop";
  };

  programs.fish.interactiveShellInit = ''
    function nsearch
        set query (if test (count $argv) -gt 0; echo $argv[1]; else; echo "."; end)
        nix search nixpkgs "$query" --json 2>/dev/null | \
          jq -r 'to_entries[] | "\(.key | sub("^[^.]+[.][^.]+[.]"; ""))\t\(.value.version // "?")\t\(.value.description // "")" | gsub("\n"; " ")' | \
          fzf --delimiter '\t' \
              --with-nth 1,2 \
              --preview 'echo {} | cut -f3' \
              --preview-window 'right:50%:wrap' \
              --bind 'ctrl-y:execute(echo {} | cut -f1 | wl-copy)+abort' \
              --header 'STRG+Y: Paketnamen kopieren | ESC: Abbrechen'
    end
  '';
}
