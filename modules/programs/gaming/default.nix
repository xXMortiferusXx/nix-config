# Gaming-Stack für nex (mortiferus).
{ config, pkgs, ... }:

{
  imports = [
    ./steam.nix
    ./gamescope.nix
    ./sunshine.nix
    ./scripts.nix
    ./udev.nix
  ];

  users.users.mortiferus.packages = with pkgs; [
    lutris
    heroic
    faugus-launcher
    gamescope
    protonplus
    winetricks
    wineWow64Packages.stable
  ];
}
