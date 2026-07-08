# systemd-user-Services für mortiferus (nex)
# Start nach graphical-session.target + noctalia.service
{ config, pkgs, lib, ... }:

let
  steamPackage = pkgs.steam.override {
    extraPkgs = pkgs: with pkgs; [
      mangohud
      bibata-cursors
    ];
    extraEnv = {
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";
    };
    extraProfile = "unset TZ";
  };
in
{
  systemd.user.tmpfiles.rules = [
    "L+ %h/.local/share/Steam/compatibilitytools.d/GE-Proton-Latest - - - - ${lib.getOutput "steamcompattool" pkgs.proton-ge-bin}"
  ];

  systemd.user.services = {
    discord = {
      Unit = {
        Description = "Discord";
        After = [ "graphical-session.target" "noctalia.service" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.discord}/bin/discord";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
    steam = {
      Unit = {
        Description = "Steam";
        After = [ "graphical-session.target" "noctalia.service" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        Environment = [
          "XCURSOR_THEME=Bibata-Modern-Ice"
          "XCURSOR_SIZE=24"
        ];
        ExecStart = "${steamPackage}/bin/steam";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
    udiskie = {
      Unit = {
        Description = "udiskie – automounter";
        After = [ "graphical-session.target" "noctalia.service" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.udiskie}/bin/udiskie";
        Restart = "on-failure";
      };
    };
    polychromatic-tray = {
      Unit = {
        Description = "Polychromatic Tray";
        After = [ "graphical-session.target" "noctalia.service" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.polychromatic}/bin/polychromatic-tray-applet";
        Restart = "on-failure";
      };
    };
  };
}
