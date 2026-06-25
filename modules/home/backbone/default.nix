{ config, pkgs, lib, ... }:

let
  pkgsList = import ./packages.nix pkgs;
in {
  home-manager.users.backbone = { config, ... }: {
    imports = [
      ./config.nix
    ];

    programs.home-manager.enable = true;
    home.packages = pkgsList;
    home.username = "backbone";
    home.homeDirectory = "/home/backbone";
    home.stateVersion = "26.05";
  };
}
