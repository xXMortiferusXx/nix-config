{ config, pkgs, ... }:
{
  # Wir nutzen programs.fish.shellAliases, damit Fish die Befehle direkt indiziert
  programs.fish.shellAliases = {
    # System & Update
    nix-switch  = "sudo nixos-rebuild switch --flake /etc/nixos#Mortiferus-PC";
    nix-update  = "pushd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch --flake .#Mortiferus-PC && popd";
    nix-clean   = "sudo nix-collect-garbage -d && sudo nixos-rebuild switch --flake /etc/nixos#Mortiferus-PC";
    conf-sync = "cd /etc/nixos && git add . && git commit -m \"Update: $(date +'%Y-%m-%d %H:%M')\" && git push origin main";
    conf = "cd /etc/nixos";    

    # Tools & Gaming
    nv-prime    = "nvidia-offload";
    scx-status  = "scxtop";
  };
}
