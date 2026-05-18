{ config, pkgs, lib, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ../../modules/system/disko-basic.nix
      ../../modules/system/common.nix
      ../../modules/system/boot-styx.nix
      ../../modules/system/environment-styx.nix
      ../../modules/hardware/intel.nix
      ../../modules/hardware/laptop-common.nix
      ../../modules/users/backbone.nix
      ../../modules/home/backbone.nix
      ../../modules/programs/editor.nix
    ];

  networking.hostName = "styx";

  # Verhindert global, dass Pakete mit CUDA-Unterstützung gebaut werden
  nixpkgs.config.cudaSupport = false;

  # Dienste für das fertige System aktivieren
  services.systembus-notify.enable = true;
  services.smartd.enable = true;
  services.earlyoom.enable = true;

  system.stateVersion = "25.11"; 
}
