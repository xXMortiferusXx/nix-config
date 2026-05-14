{ config, pkgs, lib, ... }:

{
  security.polkit.enable = true;
  programs.xwayland.enable = true;

  # ENTFERNEN:
  # services.gnome.tinysparql.enable = true;
  # services.gnome.localsearch.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # KEIN xdg-desktop-portal-gnome mehr
  };

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  environment.systemPackages = with pkgs; [
    qt6Packages.qt6ct
    libsForQt5.qt5ct
    bibata-cursors
    gnome-themes-extra
    wl-clipboard
    cliphist
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
  ];
}
