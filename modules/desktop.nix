{ config, pkgs, lib, ... }:

{
  # ────────────── Desktop-Umgebung (Niri) ──────────────
  programs.niri = {
    enable = true;
    # XWayland Support für Steam & Co
    package = pkgs.niri; 
  };
  
  security.polkit.enable = true;
  programs.dconf.enable = true;
  services.xserver.xkb.layout = "de";

  # ────────────── Login Manager (SDDM) ──────────────
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm; 
    theme = "sddm-astronaut-theme";
   settings = {
      Theme = {
        CursorTheme = "Bibata-Modern-Classic";
      };
    }; 
    # Notwendige Bibliotheken für moderne Themes (SVG/Multimedia)
    extraPackages = with pkgs.kdePackages; [
      qtmultimedia
      qtsvg
      qt5compat
    ];
  };

  # SDDM Sprach-Umgebung (Versuch, Deutsch zu erzwingen)
  systemd.services.display-manager.environment = {
     LANG = "de_DE.UTF-8";
     LC_ALL = "de_DE.UTF-8";
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
      pkgs.xdg-desktop-portal-wlr
    ];
    config.common.default = lib.mkForce "gnome";
  };

  # ────────────── System-weite Pakete (Optik & Tools) ──────────────
  environment.systemPackages = with pkgs; [
    gnome-themes-extra
    
    # XWayland Brücke für Steam
    xwayland 
    xwayland-satellite
    
    # Das Theme Paket
    sddm-astronaut
  ];

  # SDDM Theme Verlinkung (Damit SDDM den Ordner findet)
  environment.etc."sddm/themes/sddm-astronaut-theme".source = "${pkgs.sddm-astronaut}/share/sddm/themes/sddm-astronaut-theme";

  # ────────────── Schriftarten ──────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
}
