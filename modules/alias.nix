{ config, pkgs, ... }:
{
  programs.fish.shellAliases = {
    # System & Update
    nix-check  = "nix flake update && nixos-rebuild build --flake . && nvd diff /run/current-system ./result";
    nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#Mortiferus-PC";
    nix-update = "pushd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch --flake .#Mortiferus-PC && popd";
    
    # sudo nix-store --optimise hinzugefügt, damit der Store-Zugriff klappt
    nix-clean  = "sudo nix-collect-garbage -d && sudo nix-store --optimise && sudo nixos-rebuild switch --flake /etc/nixos#Mortiferus-PC";
    
    # Fehlerbehandlung für git push hinzugefügt
    conf-sync  = "cd /etc/nixos && git add . && git commit -m \"Update: $(date +'%Y-%m-%d %H:%M')\" && git push origin main || echo 'Git push fehlgeschlagen – bitte manuell prüfen'";
    conf       = "cd /etc/nixos";    

    # Tools & Gaming
    nv-prime   = "nvidia-offload";
    scx-status = "scxtop";
  };
}
