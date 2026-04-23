{ config, pkgs, lib, ... }:

{
  # ────────────── Desktop-Umgebung (Niri) ──────────────
  programs.niri = {
    enable = true;
    package = pkgs.niri; 
  };
  
  security.polkit.enable = true;
  programs.dconf.enable = true;

  # ────────────── Tastaturlayout (Systemweit, TTY & Wayland) ──────────────
  console.keyMap = "de-latin1";
  services.xserver.xkb.layout = "de";
  environment.variables.XKB_DEFAULT_LAYOUT = "de";

  # ────────────── Sprache & Lokalisierung (Fix für englische Datumsanzeige) ──────────────
  environment.variables.LANG = "de_DE.UTF-8";
  environment.variables.LC_TIME = "de_DE.UTF-8";

  # ────────────── Login Manager (greetd + ReGreet) ──────────────
  services.greetd.enable = true;
  
  programs.regreet = {
    enable = true;
    settings = {
      background = {
        path = "/var/lib/regreet/wallpapers";
        draw_mode = "cover";
      };
      GTK = {
        application_prefer_dark_theme = true;
        font_name = lib.mkForce "Gentium 12";
        icon_theme_name = lib.mkForce "Adwaita";
        cursor_theme_name = lib.mkForce "Bibata-Modern-Classic";
        cursor_size = 24;
      };
    };
  };

  # Verzeichnis für ReGreet Wallpapers erstellen & Berechtigungen setzen
  systemd.tmpfiles.rules = [
    "d /var/lib/regreet/wallpapers 0755 root root -"
  ];

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

  services.xserver.enable = false;
  environment.systemPackages = with pkgs; [
    gnome-themes-extra
    adwaita-icon-theme
    bibata-cursors
    xwayland 
    xwayland-satellite
    terminus_font
  ];

  # ────────────── Schriftarten ──────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
  ];
}
