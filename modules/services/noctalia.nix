# Noctalia v5 Paket + D-Bus
# systemd-user-Service via Home-Manager-Modul (`programs.noctalia` in home/*/default.nix).
# Paket: pkgs.noctalia aus nixpkgs (5.2.0, Binary Cache, glibc-konsistent).
# Kein Overlay mehr: früher inputs.noctalia (Flake, main) → jetzt nixpkgs.
{ config, pkgs, lib, inputs, ... }:

{
  environment.systemPackages = [
    pkgs.noctalia
    pkgs.slurp
  ];

  services.dbus.enable = true;
}
