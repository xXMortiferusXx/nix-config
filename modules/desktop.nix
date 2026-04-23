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
    wayland.enable = false;  # Erstmal X11 verwenden für Stabilität
    package = pkgs.kdePackages.sddm; 
    theme = "ltmnight";
    settings = {
      Theme = {
        CursorTheme = "Bibata-Modern-Classic";
        CursorSize = "24";
      };
      General = {
        EnableHiDPI = "true";
        InputMethod = "";
      };
      X11 = {
        ServerArguments = "-dpi 96";
      };
    }; 
    extraPackages = with pkgs.kdePackages; [
      qtmultimedia
      qtsvg
      qt5compat
      qtvirtualkeyboard
      qtwayland
    ];
  };

  systemd.services.display-manager.environment = {
    LANG = "de_DE.UTF-8";
    LC_ALL = "de_DE.UTF-8";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    XCURSOR_PATH = "${pkgs.bibata-cursors}/share/icons";
    QT_WAYLAND_FORCE_DPI = "physical";
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

  # X11-Server nur für SDDM aktivieren (minimal)
  services.xserver = {
    enable = true;
    displayManager.startx.enable = false;
    autorun = false;  # Verhindert automatischen Start
  };
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
    # Cursor-Fix für Wayland
    adwaita-icon-theme
  ];

  # Cursor-Theme systemweit setzen
  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

  # ────────────── Schriftarten ──────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
  ];
}
