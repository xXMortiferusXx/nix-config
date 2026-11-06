# Gaming-Modul für benny — gleicher Stack wie lion-pc.
# generisches game-performance-Script (scripts.nix, brightnessctl).
# ohne sunshine (Game-Streaming, nex-only).
{ config, pkgs, ... }:

let
  # Offizieller portabler Client; Wrapper kopiert Binary in beschreibbares Verzeichnis.
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
