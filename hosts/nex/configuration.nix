{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ./disk-config.nix
      ../../modules/system/common.nix
      ../../modules/system/ananicy.nix
      ../../modules/system/lsfg-vk-dev.nix
      ../../modules/system/boot-nex.nix
      ../../modules/system/environment-nex.nix
      ../../modules/hardware/nvidia-only.nix
      ../../modules/hardware/legion.nix
      # ../../modules/hardware/atlas-air.nix  # deaktiviert – Atlas Air als Garantie zurück (2026-08-18)
      ../../modules/hardware/touchpad.nix
      ../../modules/programs/gaming
      ../../modules/programs/cachyos-tools.nix
      ../../modules/programs/ideamaker.nix
      ../../modules/users/mortiferus.nix
      ../../modules/home/mortiferus
      ./config-mounts.nix
    ];

  networking.hostName = "nex";

  system.stateVersion = "26.05"; 
  
}
