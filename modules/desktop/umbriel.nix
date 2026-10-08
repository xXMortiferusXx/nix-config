# Umbriel Compositor (wlroots + SceneFX) – primäre Wayland-Session
# Paket kommt direkt aus dem Umbriel-Flake (inputs.umbriel, Overlay) statt nixpkgs.
# Autostarts laufen über graphical-session.target (kein general.autostart).
{ config, pkgs, lib, inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.umbriel.overlays.default
  ];

  # Umbriel nutzt natives wlroots-Xwayland; programs.xwayland (desktop.nix) liefert das Binary.
  programs.umbriel = {
    enable = true;
  };

  # umbriel-Portal nicht überschreiben; nur übrige Interfaces auf GTK + gnome-keyring.
  xdg.portal.config = {
    common.default = [ "gtk" ];
    umbriel = lib.mkForce {
      default = [ "umbriel" "gtk" ];
      "org.freedesktop.impl.portal.Access" = [ "gtk" ];
      "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  services.gnome.gnome-keyring.enable = true;

  # GTK-Portal-Backend (FileChooser/Notification); Screencast/Screenshot liefert der umbriel-Portal.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}