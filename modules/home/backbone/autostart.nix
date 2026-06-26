# systemd-user-Services für backbone (styx)
# Start nach graphical-session.target + noctalia.service
{ config, pkgs, ... }:

{
  systemd.user.services = {
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
  };
}
