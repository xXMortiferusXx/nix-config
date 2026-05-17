{ config, pkgs, lib, ... }:

{
  security.polkit.enable = true;
  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.tumbler.enable = true;
  services.gnome.tinysparql.enable = true;
  services.gnome.localsearch.enable = true;
  programs.xwayland.enable = true;

##### Für eventuelle Packete die noch fehlen ###### 
  environment.systemPackages = with pkgs; [
  cifs-utils
  samba
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
  ];
}
