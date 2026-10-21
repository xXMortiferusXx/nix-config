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
      ../apps/mimeapps.nix
    ];

    # Firefox: VA-API auf der HD 4000 (i965) aktivieren. Nur H.264, aber ohne
    # HW-Decode ruckelt Cloud-Gaming (Boosteroid). Nur benny (alte iGPU).
    programs.firefox.profiles.benny.settings = {
      "media.ffmpeg.vaapi.enabled" = true;
      "media.hardware-video-decoding.enabled" = true;
      "gfx.webrender.all" = true;
      "widget.dmabuf.force-enabled" = true;
    };

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
