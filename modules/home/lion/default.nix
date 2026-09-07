{ config, pkgs, lib, inputs, ... }:

let
  pkgsList = import ./packages.nix pkgs;
in {
  home-manager.backupFileExtension = "backup";

  home-manager.users.lion = { config, ... }: {
    imports = [
      ./config.nix
      ./autostart.nix
      # mpv.nix bewusst NICHT: mortiferus nutzt HRIR/GameSink (nex-Headset) — lion ohne
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