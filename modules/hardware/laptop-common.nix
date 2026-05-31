{ config, pkgs, lib, ... }:

{
  # Allgemeine Laptop-Hardware-Unterstützung
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;

  # Power Management (für Akkulaufzeit auf allen Laptops sinnvoll)
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Firmware Updates
  services.fwupd.enable = true;

  # SSD Monitoring
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.wall.enable = true;
  };

  # Touchpad-Unterstützung (Libinput)
  services.libinput.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    smartmontools
  ];
}
