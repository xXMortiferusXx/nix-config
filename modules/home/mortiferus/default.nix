{ config, pkgs, lib, inputs, ... }:

let
  pkgsList = import ./packages.nix pkgs;
in {
  home-manager.backupFileExtension = "backup";

  home-manager.users.mortiferus = { config, ... }: {
    imports = [
      inputs.noctalia.homeModules.default
      ./config.nix
      ./autostart.nix
      ./mpv.nix
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
    home.username = "mortiferus";
    home.homeDirectory = "/home/mortiferus";
    home.stateVersion = "26.05";
  };
}
