# Zusatz-Tools und Fish-Aliase für System-/Nix-Pflege.
{ config, pkgs, ... }:
let
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
    echo "== Aenderungen gegenueber /run/current-system =="
    nvd diff /run/current-system "$repo/result" || true
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
  ] ++ [ nixCheck ];

  programs.fish.shellAliases = {

    # System & Update (hostname wird per Fish-Funktion dynamisch aufgelöst)
    nix-search = "nix search nixpkgs";
    # nix-check ist ein eigenes Skript (siehe nixCheck oben) - restauriert den Lock bei Fehlern.
    nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#(hostname)";
    nix-update = "pushd /etc/nixos && nix flake update && sudo nixos-rebuild switch --flake .#(hostname) && popd";
    # Pull-Hosts uebernehmen den auf nex getesteten flake.lock. KEIN eigenes
    # `nix flake update` mehr: sonst ziehen sich lion/benny ungetestete nixpkgs-
    # Staende und brechen unabhaengig (fuse2-Vorfall 2026-10-27).
    nix-sync   = "pushd /etc/nixos && git reset --hard origin/main && git pull && sudo nixos-rebuild switch --flake .#(hostname) && popd";
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
