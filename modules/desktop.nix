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
    css = ''
      /* Hintergrund abdunkeln, falls das Bild nicht passt */
      window {
        background-color: #1a1a2e;
      }

      /* Deutsche Uhrzeit & Datum Styling */
      .clock {
        font-size: 32px;
        font-weight: bold;
        color: #ffffff;
        text-shadow: 0 2px 6px rgba(0, 0, 0, 0.6);
      }

      .date {
        font-size: 16px;
        color: #e0e0e0;
        text-shadow: 0 2px 6px rgba(0, 0, 0, 0.6);
        margin-bottom: 12px;
      }

      /* Login Box Styling */
      .login-box {
        background-color: rgba(20, 20, 25, 0.85);
        border-radius: 16px;
        border: 1px solid rgba(255, 255, 255, 0.1);
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
        padding: 24px;
      }

      .user-box {
        color: #ffffff;
        font-size: 18px;
        font-weight: bold;
      }

      /* Eingabefelder & Buttons */
      entry, button {
        border-radius: 10px;
        border: 1px solid rgba(255, 255, 255, 0.15);
        background-color: rgba(255, 255, 255, 0.08);
        color: #ffffff;
        padding: 8px 12px;
      }

      entry:focus {
        border-color: #765934;
        background-color: rgba(255, 255, 255, 0.12);
      }

      button:hover {
        background-color: rgba(255, 255, 255, 0.15);
      }

      button:active {
        background-color: #765934;
        color: #ffffff;
      }

      /* Power Buttons */
      .power-button {
        background-color: transparent;
        border: none;
        color: #cccccc;
      }
      .power-button:hover {
        color: #ff5555;
      }
    '';
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
