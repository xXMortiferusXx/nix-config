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
    sddm-astronaut
    (pkgs.callPackage ./sddm-themes/ltmnight.nix {})
  ];

  environment.etc."sddm/themes/sddm-astronaut-theme".source = "${pkgs.sddm-astronaut}/share/sddm/themes/sddm-astronaut-theme";

  # ────────────── Schriftarten ──────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
  ];
}
