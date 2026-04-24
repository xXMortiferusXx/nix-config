{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fzf
    jq
    wl-clipboard
  ];

  programs.fish.shellAliases = {
    # System & Update
    nix-check  = "nix flake update && nixos-rebuild build --flake . && nvd diff /run/current-system ./result";
    nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#Mortiferus-PC";
    nix-update = "pushd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch --flake .#Mortiferus-PC && popd";
    nix-clean  = "sudo nix-collect-garbage -d && sudo nix-store --optimise && sudo nixos-rebuild switch --flake /etc/nixos#Mortiferus-PC";
    conf-sync  = "cd /etc/nixos && git add . && git commit -m \"Update: $(date +'%Y-%m-%d %H:%M')\" && git push origin main || echo 'Git push fehlgeschlagen – bitte manuell prüfen'";
    conf       = "cd /etc/nixos";

    # Tools & Gaming
    nv-prime   = "nvidia-offload";
    scx-status = "scxtop";
  };

  programs.fish.interactiveShellInit = ''
    function nsearch
        set query (if test (count $argv) -gt 0; echo $argv[1]; else; echo "."; end)
        nix search nixpkgs# $query --json 2>/dev/null | \
          jq -r 'to_entries[] | "\(.key)\t\(.key | split(".") | last)\t\(.value.version // "unbekannt")\t\(.value.description // "keine Beschreibung")" | gsub("\n"; " ")' | \
          fzf --delimiter '\t' \
              --with-nth 2,3 \
              --preview 'echo {} | cut -f4' \
              --preview-window 'right:40%' \
              --bind 'ctrl-y:execute(echo {} | cut -f2 | wl-copy)' \
              --header 'STRG+Y: Paketname kopieren | ESC: Abbrechen'
    end
  '';
}
