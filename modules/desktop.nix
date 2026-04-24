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

  # ────────────── Login Manager (SDDM) ──────────────
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false; # X11 verwenden, um Mauszeiger-Bugs zu vermeiden
    package = pkgs.kdePackages.sddm; 
    theme = "ltmnight";
    setupScript = ''
    ${pkgs.xrdb}/bin/xrdb -merge <<EOF
    Xcursor.theme: Bibata-Modern-Classic
    Xcursor.size: 24
    EOF
    '';
    #settings Deaktiviert da momentan über setupScript und xrdb gelöst!
    #settings = {
    #  Theme = {
    #    CursorTheme = "Bibata-Modern-Classic";
    #    CursorSize = 24;
    #  };
    #}; 
    extraPackages = with pkgs; [
      kdePackages.qtmultimedia
      kdePackages.qtsvg
      kdePackages.qt5compat
      kdePackages.qtvirtualkeyboard
      bibata-cursors #Nötig ? Sicher ist Sicher :-)
    ];
  };

  # Systemweite Cursor-Einstellungen über Umgebungsvariablen
  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

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
    ];
    config = {
      common = {
        default = [ "gnome" ];
        "org.freedesktop.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.portal.ScreenCast" = [ "gnome" ];
      };
    };
  };

  # X11-Unterstützung aktivieren, damit SDDM im X11-Modus stabil läuft
  services.xserver.enable = true;
  
  environment.systemPackages = with pkgs; [
    bibata-cursors
    gnome-themes-extra
    xwayland 
    xwayland-satellite
    (pkgs.callPackage ./sddm-themes/ltmnight.nix {})
  ];

  # ────────────── Schriftarten ──────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
  ];
}
