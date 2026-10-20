# Lenovo Legion Gaming-Laptop (nex)
# AMD µcode, Conservation Mode (60%), Xbox (xone), uinput, irqbalance
{ config, pkgs, lib, ... }:

{
  imports = [ ./laptop-common.nix ./xbox-controller.nix ];

  # iwlmvm power_scheme=1: verhindert tx_retries durch Firmware-Power-Save.
  boot.extraModprobeConfig = "options iwlmvm power_scheme=1";

  hardware.cpu.amd.updateMicrocode = true;

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
