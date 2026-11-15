# Umbriel Compositor (wlroots + SceneFX) – primäre Wayland-Session
# Paket kommt direkt aus dem Umbriel-Flake (inputs.umbriel) statt nixpkgs.
# Autostarts laufen über graphical-session.target (kein general.autostart).
{ config, pkgs, lib, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  # Bewusst KEIN Overlay: das Overlay (`final.callPackage`) baut Umbriel gegen UNSER
  # nixpkgs, das taeglich per `nix flake update` wandert -> Store-Pfad weicht vom
  # CI-Build ab -> Cache-Miss. `inputs.umbriel.packages` ist exakt das, was die CI
  # baut und nach umbriel.cachix.org pusht (Umbriels eigener nixpkgs-Lock, weil
  # `inputs.nixpkgs.follows` in flake.nix entfernt ist) -> garantierter Treffer.
  # Umbriel nutzt natives wlroots-Xwayland; programs.xwayland (desktop.nix) liefert das Binary.
  programs.umbriel = {
    enable = true;
    package = inputs.umbriel.packages.${system}.default;
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