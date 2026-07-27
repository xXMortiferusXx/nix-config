# Niri Compositor (scrollable-tiling Wayland)
# + gnome-keyring als systemd-Service + xdg-portal mit GTK+gnome-keyring + xwayland-satellite
# Paket-Quelle: sodiboo/niri-flake (Overlay + niri.cachix.org Binary Cache)
{ config, pkgs, lib, inputs, ... }:

{
  # sodiboo/niri-flake Overlay aktivieren (für niri-stable / niri-unstable)
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  # Binary Cache für niri-flake (verhindert lokales Kompilieren)
  nix.settings = {
    substituters = [ "https://niri.cachix.org" ];
    trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
  };

  programs.niri = {
    enable = true;
    # niri-unstable = aktueller main-Branch (immer vor Merge im Cache)
    package = pkgs.niri-unstable;
  };

  xdg.portal = {
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
#      pkgs.xdg-desktop-portal-gnome
    ];
    config = {
      common.default = [ "gtk" ];
      niri = lib.mkForce {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.Access" = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
  };

  services.gnome.gnome-keyring.enable = true;

  systemd.user.services.xwayland-satellite = {
    serviceConfig.ExecCondition = "${pkgs.bash}/bin/bash -c '[ \"$XDG_CURRENT_DESKTOP\" = \"niri\" ]'";
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
