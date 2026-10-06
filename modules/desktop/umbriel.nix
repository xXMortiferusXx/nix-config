# Umbriel Compositor (wlroots 0.20 + SceneFX) – primäre Wayland-Session
# Paket-Quelle: direkt vom Umbriel-Flake (inputs.umbriel, Overlay), statt nixpkgs,
# damit Fixes zeitnah ankommen (nixpkgs pinnt oft lange alte Revs).
# Das nixpkgs-Modul `programs.umbriel` registriert die Session (.desktop via
# start-umbriel), installiert die systemd-Units (systemd.packages) und ein
# Portal-Config; der Overlay ersetzt nur das Paket `pkgs.umbriel`.
#
# Autostarts bleiben unverändert über graphical-session.target laufen:
# Umbriels start-umbriel → umbriel.service → umbriel-session.target
# (BindsTo=graphical-session.target, Wants=xdg-desktop-autostart.target),
# damit starten noctalia/steam/discord/… genau wie unter niri.
# → general.autostart wird bewusst NICHT gesetzt (kein Doppelstart mit noctalia.service).
{ config, pkgs, lib, inputs, ... }:

{
  # Umbriel-Paket aus dem Flake (neueste Rev, lokaler Build statt Cache).
  nixpkgs.overlays = [
    inputs.umbriel.overlays.default
  ];

  # X11: Seit Rev 4c89178 (2026-09-29) nutzt Umbriel natives wlroots-Xwayland
  # statt xwayland-satellite. Das Flake-Paket ist ein makeBinaryWrapper, der
  # `Xwayland` selbst in den PATH des Compositors legt; `programs.xwayland`
  # (desktop.nix, shared) liefert das Binary. xwayland-satellite ist damit
  # obsolet → entfernt. general.xwayland = true startet Xwayland lazy.
  programs.umbriel = {
    enable = true;
  };

  # Portal-Config: Der umbriel-Portal (configPackages des Moduls) liefert die
  # Screencast/Screenshot-Zuordnung → nicht überschreiben. Hier nur die
  # übrigen Interfaces auf GTK + gnome-keyring (wie unter niri).
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

  # GTK-Portal-Backend (FileChooser/Notification) – kam vorher aus niri.nix
  # (niri ist entfernt). Screencast/Screenshot liefert der umbriel-Portal.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}