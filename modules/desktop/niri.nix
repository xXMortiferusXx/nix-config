{ config, pkgs, lib, ... }:

{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  # Polkit-Agent für grafische Passwortabfragen DEAKTIVIERT DA NOCTALIA EINEN MIT BRINGT !!
  #systemd.user.services.polkit-gnome-authentication-agent-1 = {
  #  description = "gnome-polkit-agent";
  #  wantedBy = [ "graphical-session.target" ];
  #  serviceConfig = {
  #    Type = "simple";
  #    ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
  #    Restart = "on-failure";
  #    RestartSec = 1;
  #    TimeoutStopSec = 10;
  #  };
  #};

  # XDG Desktop Portals
  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    config.common.default = [ "gtk" ];
    config.niri.default = lib.mkForce [ "gtk" "gnome" ];
  };

  # Umgebungsvariablen für Wayland & XWayland Fixes
  environment.variables = {
    NIXOS_OZONE_WL = "1"; 
    DISPLAY = ":0";
    XDG_SESSION_TYPE = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    # Fix für Java-Apps (XWayland)
    _JAVA_AWT_WM_NONREPARENTING = "1";
    # GTK File Chooser Fix (Zwingt die Nutzung des Portals)
    GTK_USE_PORTAL = "1";
  };

  services.displayManager.sessionPackages = [ pkgs.niri ];

  programs.dconf.enable = true;
  services.xserver.xkb.layout = "de";

  # Erforderliche Systempakete
  environment.systemPackages = with pkgs; [
    polkit_gnome
    xwayland
  ];
}
