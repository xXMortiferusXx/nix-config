# Lenovo Legion Gaming-Laptop (nex)
# AMD µcode, Conservation Mode (60%), Razer, Xbox-Controller, uinput, irqbalance
{ config, pkgs, lib, ... }:

{
  imports = [ ./laptop-common.nix ];

  boot.extraModulePackages = [
    config.boot.kernelPackages.lenovo-legion-module
  ];

  # iwlmvm power_scheme=1: verhindert tx_retries durch Firmware-Power-Save.
  boot.extraModprobeConfig = "options iwlmvm power_scheme=1";

  hardware.cpu.amd.updateMicrocode = true;

  hardware.uinput.enable = true;
  hardware.xone.enable = true;
  hardware.xpadneo.enable = true;
  hardware.openrazer.enable = true;

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
