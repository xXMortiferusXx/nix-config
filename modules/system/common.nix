{ config, pkgs, ... }:

{
  imports = [
    ./locale.nix
    ./networking.nix
    ./security.nix
    ./nix-settings.nix
    ../hardware/audio.nix
    ../services/printing.nix
    ../services/noctalia.nix
    ../programs/shell.nix
    ../programs/editor.nix
    ../programs/terminal.nix
    ../programs/tools.nix
    ../desktop/desktop.nix
    ../desktop/sddm.nix
    ../desktop/niri.nix
    ../desktop/plasma.nix
    ../desktop/hyprland.nix
  ];
}
