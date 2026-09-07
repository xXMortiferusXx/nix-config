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
    gamescope
    #umu-launcher
    protonplus
  ];
}
