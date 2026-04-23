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
  # services.greetd.enable wird automatisch durch programs.regreet gesetzt.
  # Der manuelle settings-Block wurde entfernt, da er die automatische 
  # User-Erstellung von ReGreet stört und zur Assertion führt.
  services.greetd.enable = true;
  
  programs.regreet = {
    enable = true;
    settings = {
      background = {
        # Wenn 'path' ein Verzeichnis ist, wählt ReGreet beim Start ZUFÄLLIG ein Bild daraus.
        path = "/var/lib/regreet/wallpapers";
        draw_mode = "fill"; # Wichtig: Skaliert das Bild korrekt auf den Monitor
      };
      GTK = {
        application_prefer_dark_theme = lib.mkForce true;
        font_name = lib.mkForce "Gentium 12";
        icon_theme_name = lib.mkForce "Adwaita";
        cursor_theme_name = lib.mkForce "Bibata-Modern-Classic";
        cursor_size = lib.mkForce 24;
      };
    };
  };

  # Verzeichnis für ReGreet Wallpapers erstellen
  # Owner: root, Group: users (rwx), Others: r-x (greeter kann lesen)
  # /var/lib ist persistent, der Ordner bleibt also nach einem Reboot erhalten.
  systemd.tmpfiles.rules = [
    "d /var/lib/regreet/wallpapers 0775 root users -"
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
