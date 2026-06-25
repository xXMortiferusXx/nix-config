{ config, pkgs, lib, ... }:

let
  pkgsList = import ./packages.nix pkgs;
in {
  home-manager.backupFileExtension = "backup";

  home-manager.users.mortiferus = { config, ... }: {
    imports = [
      ./config.nix
      ./mangohud.nix
      ./mpv.nix
    ];

    programs.home-manager.enable = true;
    home.packages = pkgsList;
    home.username = "mortiferus";
    home.homeDirectory = "/home/mortiferus";
    home.stateVersion = "26.05";
  };
}
