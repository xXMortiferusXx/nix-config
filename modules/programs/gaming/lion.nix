# Gaming-Modul für lion-pc — gleiche Gaming-Stack wie nex, ABER:
# - ohne sunshine (Game-Streaming, nex-only)
# - Pakete für User lion statt mortiferus
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./steam.nix
    ./gamescope.nix
    ./scripts-lion.nix # lion-spezifisch: DDC/CI statt brightnessctl
    ./udev.nix
  ];

  users.users.lion.packages = with pkgs; [
    lutris
    heroic
    gamescope
    protonplus

    inputs.bedrock-on-linux.packages."x86_64-linux".default
  ];
}