# Lenovo Legion Gaming-Laptop (nex)
# AMD µcode, Conservation Mode (60%), Razer, Xbox-Controller, uinput, irqbalance
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

  systemd.services.legion-conservation-mode = {
    description = "Lenovo Legion Battery Conservation Mode (60%)";
    after = [ "systemd-modules-load.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 1 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode'";
      RemainAfterExit = true;
    };
  };
}
