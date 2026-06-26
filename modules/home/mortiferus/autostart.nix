# systemd-user-Services für mortiferus (nex)
# Start nach graphical-session.target + noctalia.service
# vesktop: +sleep 3 wg. Tray-Race-Condition
{ config, pkgs, ... }:

{
  systemd.user.services = {
    vesktop = {
      Unit = {
        Description = "Vesktop";
        After = [ "graphical-session.target" "noctalia.service" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
        ExecStart = "${pkgs.vesktop}/bin/vesktop";
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
        ExecStart = "${pkgs.steam}/bin/steam";
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
