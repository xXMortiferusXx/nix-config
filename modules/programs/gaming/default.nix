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
    #umu-launcher
    protonplus
    winetricks
    wineWow64Packages.stable
  ];
}
