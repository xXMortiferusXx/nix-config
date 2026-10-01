# Gaming-Modul fuer benny
# Gleicher Stack wie lion-pc, aber:
# - generisches game-performance-Script (scripts.nix, brightnessctl) statt
#   lion's DDC/CI-Variante — benny's Monitor-Setup ist noch nicht bekannt
# - ohne sunshine (Game-Streaming, nex-only)
{ config, pkgs, ... }:

let
  # Offizieller portabler Linux-Client (nicht auf Flathub/nixpkgs) – Derivation
  # in pkgs/boosteroid. Wrapper kopiert die Binary in ein beschreibbares
  # Verzeichnis (Log/Config + Selbst-Updater).
  boosteroid = pkgs.callPackage ../../../pkgs/boosteroid { };
in

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
    boosteroid
  ];
}
