# Noctalia v5 Paket + D-Bus
# systemd-user-Service via Home-Manager-Modul (programs.noctalia).
{ config, pkgs, lib, inputs, ... }:

{
  environment.systemPackages = [
    pkgs.noctalia
    pkgs.slurp
  ];

  services.dbus.enable = true;
}
