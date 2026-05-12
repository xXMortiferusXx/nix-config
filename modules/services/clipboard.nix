{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wl-clipboard
    cliphist
  ];

  # Clipboard Historie für Text
  systemd.user.services.cliphist = {
    description = "Clipboard history service (text)";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store'";
      Restart = "always";
      RestartSec = 3;
    };
  };

  # Clipboard Historie für Bilder
  systemd.user.services.cliphist-images = {
    description = "Clipboard history service (images)";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store'";
      Restart = "always";
      RestartSec = 3;
    };
  };
}
