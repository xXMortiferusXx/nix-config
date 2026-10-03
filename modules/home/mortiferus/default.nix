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
      ./mangohud.nix
      ../firefox.nix
    ];

    programs.home-manager.enable = true;
    programs.noctalia.enable = true;
    programs.noctalia.systemd.enable = true;

    home.packages = pkgsList;
    home.username = "mortiferus";
    home.homeDirectory = "/home/mortiferus";
    home.stateVersion = "26.05";
  };
}
