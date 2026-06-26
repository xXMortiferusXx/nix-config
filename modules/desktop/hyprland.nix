# Hyprland Compositor + gnome-keyring als systemd-Service
{ config, pkgs, lib, ... }: 

{
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    hyprshot
  ];
}
