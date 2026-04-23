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
  # "de-latin1" stellt sicher, dass Umlaute im TTY korrekt funktionieren
  console.keyMap = "de-latin1";
  services.xserver.xkb.layout = "de";
  # Wayland nutzt diese Umgebungsvariable für das Tastaturlayout
  environment.variables.XKB_DEFAULT_LAYOUT = "de";

  # ────────────── Login Manager (greetd + ReGreet) ──────────────
  services.greetd.enable = true;
  
  programs.regreet = {
    enable = true;
    settings = {
      background = {
        # Beschreibbarer Pfad für dynamische Wallpapers
        # Noctalia kann hier über den 'wallpaperChange' Hook das Bild ablegen.
        path = "/var/lib/regreet/wallpaper.jpg";
      };
      GTK = {
        font_name = lib.mkForce "Gentium 12";
        icon_theme_name = lib.mkForce "Adwaita";
        cursor_theme_name = lib.mkForce "Bibata-Modern-Classic";
        cursor_size = lib.mkForce 24;
      };
    };
  };

  # Verzeichnis für ReGreet Wallpaper erstellen & Berechtigungen setzen
  # greeter-User kann lesen, deine User-Gruppe (z.B. users) kann schreiben
  systemd.tmpfiles.rules = [
    "d /var/lib/regreet 0755 greeter users -"
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
