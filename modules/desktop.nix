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
        # ReGreet lädt dieses Bild. Da ReGreet als separater User ('greeter') läuft,
        # muss das Bild an einem global lesbaren Ort liegen.
        # Noctalia kann über den 'wallpaperChange' Hook das aktuelle Bild hierhin kopieren.
        path = "/etc/nixos/wallpaper.jpg";
      };
      GTK = {
        font_name = "Gentium 12";
        icon_theme_name = "Adwaita";
        cursor_theme_name = "Bibata-Modern-Classic";
        cursor_size = 24;
      };
    };
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
