# Noctalia v5 Paket-Installation + D-Bus
# systemd-user-Service wird via Home-Manager-Modul in home/*/default.nix aktiviert
# Paket-Quelle: Overlay vom Noctalia-Flake (inputs.noctalia) statt nixpkgs, weil
# nixpkgs den alten Tag v5.0.0-beta.10 pinnt (Farb-Templates veraltet).
# Der Overlay registriert das Flake-Paket direkt als pkgs.noctalia statt per
# final.callPackage selbst zu bauen: letzteres baut gegen unsere nixos-unstable-
# Rev (anderer Store-Path als der noctalia.cachix.org-Prebuild → Cache-Miss).
{ config, pkgs, lib, inputs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      noctalia = inputs.noctalia.packages.${final.stdenv.hostPlatform.system}.default;
    })
  ];

  environment.systemPackages = [
    pkgs.noctalia
    pkgs.slurp
  ];

  services.dbus.enable = true;
}
