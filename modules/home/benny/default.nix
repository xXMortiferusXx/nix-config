{ config, pkgs, lib, inputs, ... }:

let
  pkgsList = import ./packages.nix pkgs;

  # Edge mit Performance-Governor starten (Cloud-Gaming via Browser).
  # game-performance (Systempaket) setzt Governor/PPD und stellt sie danach zurueck.
  edgePerformance = pkgs.writeShellScriptBin "edge-performance" ''
    exec game-performance microsoft-edge "$@"
  '';
in {
  home-manager.backupFileExtension = "backup";

  home-manager.users.benny = { config, ... }: {
    imports = [
      ./config.nix
      ./autostart.nix
      ../firefox.nix
      ../apps/mimeapps.nix
    ];

    # Firefox: VA-API auf der HD 2500 (i965) aktivieren. Nur H.264, aber ohne
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

    home.packages = pkgsList ++ [ edgePerformance ];

    xdg.desktopEntries."microsoft-edge-performance" = {
      name = "Microsoft Edge (Performance)";
      comment = "Edge mit Performance-Governor (Cloud-Gaming)";
      exec = "${edgePerformance}/bin/edge-performance %U";
      icon = "microsoft-edge";
      categories = [ "Network" "WebBrowser" ];
      startupNotify = true;
      settings.StartupWMClass = "microsoft-edge";
    };
    home.username = "benny";
    home.homeDirectory = "/home/benny";
    home.stateVersion = "26.05";
  };
}
