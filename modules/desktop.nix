{ config, pkgs, lib, ... }:

{
  # ────────────── Desktop-Umgebung (Niri) ──────────────
  programs.niri = {
    enable = true;
    package = pkgs.niri; 
  };
  
  security.polkit.enable = true;
  programs.dconf.enable = true;
  services.xserver.xkb.layout = "de";

  # ────────────── Login Manager (greetd + nwg-hello) ──────────────
  services.greetd = {
    enable = true;
    vt = 1;
    settings = {
      default_session = {
        command = "${pkgs.nwg-hello}/bin/nwg-hello";
        user = "nwg-hello";
      };
    };
  };

  programs.nwg-hello = {
    enable = true;
  };

  i18n.extraLocaleSettings = {
    LC_TIME = "de_DE.UTF-8";
  };

  # ────────────── Portale (Screenshots & Fenster-Sharing) ──────────────
  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gnome 
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "gnome" ];
        "org.freedesktop.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.portal.ScreenCast" = [ "gnome" ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    bibata-cursors
    gnome-themes-extra
    xwayland 
    xwayland-satellite
    nwg-hello
  ];

  # ────────────── Schriftarten ──────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
  ];
}
