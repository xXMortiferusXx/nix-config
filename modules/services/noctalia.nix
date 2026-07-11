# Noctalia v5 Paket-Installation + D-Bus
# systemd-user-Service wird via Home-Manager-Modul in home/*/default.nix aktiviert
{ config, pkgs, inputs, ... }:

{
  environment.systemPackages = [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.slurp
  ];

  services.dbus.enable = true;
}
