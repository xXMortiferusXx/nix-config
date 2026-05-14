{ config, pkgs, lib, ... }:

{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  xdg.portal = {
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common.default = [ "gtk" ];
      niri.default = [ "gtk" "gnome" ];
    };
  };

  systemd.user.services.xwayland-satellite = {
    serviceConfig.ExecCondition = "${pkgs.bash}/bin/bash -c '[ \"$XDG_CURRENT_DESKTOP\" = \"niri\"
]'";
  };

  services.displayManager.sessionPackages = [ pkgs.niri ];

  programs.dconf.enable = true;
  services.xserver.xkb.layout = "de";

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
