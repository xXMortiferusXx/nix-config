# Gaming-Modul fuer benny
# Gleicher Stack wie lion-pc, aber:
# - generisches game-performance-Script (scripts.nix, brightnessctl) statt
#   lion's DDC/CI-Variante — benny's Monitor-Setup ist noch nicht bekannt
# - ohne sunshine (Game-Streaming, nex-only)
{ config, pkgs, ... }:

{
  imports = [
    ./steam.nix
    ./gamescope.nix
    ./scripts.nix
    ./udev.nix
  ];

  users.users.benny.packages = with pkgs; [
    lutris
    heroic
    gamescope
    protonplus
  ];
}
