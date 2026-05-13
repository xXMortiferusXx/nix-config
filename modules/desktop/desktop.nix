{ config, pkgs, lib, ... }:

{
  imports = [
  ];

  security.polkit.enable = true;
  programs.xwayland.enable = true;
  services.gnome.tinysparql.enable = true;
  services.gnome.localsearch.enable = true;
  

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
  };

  environment.systemPackages = with pkgs; [
    bibata-cursors
    gnome-themes-extra
    xwayland-satellite
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
