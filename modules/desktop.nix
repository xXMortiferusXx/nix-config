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
    wayland.enable = true;
    package = pkgs.kdePackages.sddm; 
    theme = "ltmnight";
    settings = {
      Theme = {
        CursorTheme = "Bibata-Modern-Classic";
        CursorSize = "24";
      };
      General = {
        # Cursor explizit für SDDM aktivieren
        EnableHiDPI = "true";
      };
      Wayland = {
        # Wayland-spezifische Cursor-Einstellungen
        CompositorCommand = "kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1";
      };
    }; 
    extraPackages = with pkgs.kdePackages; [
      qtmultimedia
      qtsvg
      qt5compat
      qtvirtualkeyboard
    ];
  };

  systemd.services.display-manager.environment = {
    LANG = "de_DE.UTF-8";
    LC_ALL = "de_DE.UTF-8";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    # SDDM unter Wayland sucht oft nur in explizit gesetzten Pfaden
    XCURSOR_PATH = "${pkgs.bibata-cursors}/share/icons";
    # Zusätzliche Wayland-spezifische Cursor-Einstellungen
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  i18n.extraLocaleSettings = {
    LC_TIME = "de_DE.UTF-8";
  };

  # ────────────── Portale (Screenshots & Fenster-Sharing) ──────────────
  # Hinweis: xdg-desktop-portal-wlr wurde entfernt, da es für wlroots-Compositors
  # (Sway etc.) gedacht ist und bei Niri Konflikte verursachen kann.
  # xdg-desktop-portal-gnome übernimmt alle nötigen Funktionen für Niri.
  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gnome 
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "gnome" ];
        # Screenshot-Portal explizit auf gnome setzen
        "org.freedesktop.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.portal.ScreenCast" = [ "gnome" ];
      };
    };
  };

  services.xserver.enable = false;
  environment.systemPackages = with pkgs; [
    gnome-themes-extra
    xwayland 
    xwayland-satellite
    (pkgs.callPackage ./sddm-themes/ltmnight.nix {})
    # Cursor-Theme systemweit verfügbar machen, damit SDDM & Apps es finden
    bibata-cursors
    # Zusätzliche Cursor-Unterstützung
    libsForQt5.qt5.qtwayland
    kdePackages.qtwayland
  ];

  # ────────────── Schriftarten ──────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
  ];
}
