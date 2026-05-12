{ config, pkgs, ... }:
let
  speedtestAuto = pkgs.writeShellScriptBin "speedtest-auto" ''
    # Ookla wählt standardmäßig automatisch den optimalen Server
    exec ${pkgs.ookla-speedtest}/bin/speedtest --accept-license --accept-gdpr "$@"
  '';
in
{
  environment.systemPackages = with pkgs; [
    fzf
    jq
    wl-clipboard
    cliphist
    ookla-speedtest
    speedtestAuto
  ];

  programs.fish.shellAliases = {
    # Editor Aliase
    vi    = "nvim";
    vim   = "nvim";

    # System & Update (Nutzt die Fish-Syntax (hostname) für dynamische Auflösung)
    nix-search = "nix search nixpkgs";
    nix-check  = "nix flake update && nixos-rebuild build --flake .#(hostname) && nvd diff /run/current-system ./result";
    nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#(hostname)";
    nix-update = "pushd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch --flake .#(hostname) && popd";
    nix-sync   = "pushd /etc/nixos && git reset --hard origin/main && git pull && sudo nixos-rebuild switch --flake .#(hostname) && popd";
    night-update = "niri msg action power-off-monitors && pushd /etc/nixos && nix flake update && sudo systemd-inhibit --why='Nightly Update' --mode=block nixos-rebuild switch --flake .#(hostname); popd";

    # Aufräumen
    nix-clean  = "sudo nix-collect-garbage -d && sudo nix-store --optimise && sudo nixos-rebuild switch --flake /etc/nixos#(hostname)";

    # Config-Sync (Git ohne sudo für SSH-Keys)
    conf-sync  = "pushd /etc/nixos && git add . && git commit -m \"Update: $(date +'%Y-%m-%d %H:%M')\" && git push origin main; popd";
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
