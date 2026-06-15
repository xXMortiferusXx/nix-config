# plasma.nix
{ config, pkgs, lib, ... }:

{
  services.desktopManager.plasma6.enable = true;

  # Plasma-spezifische Pakete
  environment.systemPackages = with pkgs; [
    libsForQt5.qt5.qtwayland
    kdePackages.qtwayland    
    kdePackages.plasma-browser-integration
    kdePackages.kde-gtk-config
  ];
}
