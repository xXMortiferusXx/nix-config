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

  # ────────────── Login Manager (greetd + ReGreet) ──────────────
  services.greetd.enable = true;
  
  # ReGreet benötigt einen Wayland-Compositor. NixOS kümmert sich darum automatisch,
  # wenn programs.regreet aktiviert wird. Es ersetzt die manuelle command-Zuweisung.
  programs.regreet = {
    enable = true;
    # Optional: Hier können später Theme/Icon-Einstellungen vorgenommen werden
    # settings = { ... };
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
  ];

  # ────────────── Schriftarten ──────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
  ];
}
