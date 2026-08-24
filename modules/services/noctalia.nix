# Noctalia v5 Paket-Installation + D-Bus
# systemd-user-Service wird via Home-Manager-Modul in home/*/default.nix aktiviert
{ config, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.noctalia
    pkgs.slurp
  ];

  services.dbus.enable = true;
}
