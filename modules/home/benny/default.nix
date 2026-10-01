{ config, pkgs, lib, inputs, ... }:

let
  pkgsList = import ./packages.nix pkgs;
in {
  home-manager.backupFileExtension = "backup";

  home-manager.users.benny = { config, ... }: {
    imports = [
      ./config.nix
      ./autostart.nix
      ../firefox.nix
    ];

    programs.mangohud = {
      enable = true;
      enableSessionWide = false;
      settings = { };
    };

    programs.home-manager.enable = true;
    programs.noctalia.enable = true;
    programs.noctalia.systemd.enable = true;

    home.packages = pkgsList;
    home.username = "benny";
    home.homeDirectory = "/home/benny";
    home.stateVersion = "26.05";
  };
}
