{ config, pkgs, lib, inputs, ... }:

let
  pkgsList = import ./packages.nix pkgs;
in {
  home-manager.backupFileExtension = "backup";

  home-manager.users.mortiferus = { config, ... }: {
    imports = [
      ./config.nix
      ./autostart.nix
      ./mpv.nix
      ../apps/mimeapps.nix
      ../firefox.nix
    ];

    programs.home-manager.enable = true;

    # Config wird von GOverlay verwaltet (settings leer = kein HM-Symlink).
    programs.mangohud = {
      enable = true;
      enableSessionWide = false;
      settings = { };
    };

    programs.noctalia.enable = true;
    programs.noctalia.systemd.enable = true;

    home.packages = pkgsList;
    home.username = "mortiferus";
    home.homeDirectory = "/home/mortiferus";
    home.stateVersion = "26.05";
  };
}
