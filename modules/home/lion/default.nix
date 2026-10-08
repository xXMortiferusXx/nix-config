{ config, pkgs, lib, inputs, ... }:

let
  pkgsList = import ./packages.nix pkgs;
in {
  home-manager.backupFileExtension = "backup";

  home-manager.users.lion = { config, ... }: {
    imports = [
      ./config.nix
      ./autostart.nix
      ../firefox.nix
      ../apps/mimeapps.nix
      # mpv.nix bewusst nicht (mortiferus-spezifisch: HRIR/GameSink).
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
    home.username = "lion";
    home.homeDirectory = "/home/lion";
    home.stateVersion = "26.05";
  };
}