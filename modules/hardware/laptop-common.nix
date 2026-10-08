# Gemeinsame Laptop-Module für alle Hosts
# Bluetooth, power-profiles-daemon, upower, fwupd, smartd, libinput
{ config, pkgs, lib, ... }:

{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  services.fwupd.enable = true;

  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.wall.enable = true;
  };

  services.libinput.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    smartmontools
  ];
}
