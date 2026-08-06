# Hyprland Compositor + gnome-keyring als systemd-Service
# Paket-Quelle: offizieller Hyprland-Flake (github:hyprwm/Hyprland) mit hyprland.cachix.org Cache
{ inputs, config, pkgs, lib, ... }:

{
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  services.gnome.gnome-keyring.enable = true;

  # Binary Cache für den offiziellen Hyprland-Flake (verhindert lokales Kompilieren)
  # Offizielle Werte laut Hyprland-Howto (key: a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=)
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    # Nötig, damit auch Nicht-Root-Nutzer den Substituter/Keys nutzen dürfen
    trusted-users = [ "root" "@wheel" ];
  };

  environment.systemPackages = with pkgs; [
    # hyprshot überschreiben, damit es auf das Flake-Hyprland zeigt
    # (statt aufs nixpkgs-Hyprland, dessen Build aktuell kaputt ist)
    (pkgs.hyprshot.override {
      hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    })
  ];
}
