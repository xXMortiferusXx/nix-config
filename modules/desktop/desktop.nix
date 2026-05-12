{ config, pkgs, lib, ... }:

{
  imports = [
  ];

  security.polkit.enable = true;

  programs.xwayland.enable = true;

  xdg.portal = {
    enable = true;
  };

  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
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
