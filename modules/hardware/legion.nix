{ config, pkgs, lib, ... }:

{
  imports = [ ./laptop-common.nix ];
  # Lenovo Legion spezifische Features
  boot.extraModulePackages = [
    config.boot.kernelPackages.lenovo-legion-module
  ];

  # AMD CPU Optimierungen
  hardware.cpu.amd.updateMicrocode = true;

  # Gaming Peripherie & Controller
  hardware.uinput.enable = true;
  hardware.xone.enable = true;
  hardware.xpadneo.enable = true;
  hardware.openrazer.enable = true;

  # Interrupt Balancing (gut für Gaming Hubs/Viel Peripherie)
  services.irqbalance.enable = true;

  # Systembus-Notify für Smartd/Earlyoom
  services.systembus-notify.enable = lib.mkForce true;

  environment.systemPackages = with pkgs; [
    lenovo-legion
  ];
}
