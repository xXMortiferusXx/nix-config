{ config, pkgs, lib, ... }:

{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  xdg.portal = {
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    config = {
      common.default = [ "gtk" ];
      niri = lib.mkForce {
        default = [ "gtk" "gnome" ];
        "org.freedesktop.impl.portal.Access" = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
  };

  systemd.user.services.xwayland-satellite = {
    serviceConfig.ExecCondition = "${pkgs.bash}/bin/bash -c '[ \"$XDG_CURRENT_DESKTOP\" = \"niri\"
]'";
  };

  services.displayManager.sessionPackages = [ pkgs.niri ];

 
  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
