{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ./disk-config.nix
      ./disko-gaming.nix
      ../../modules/system/common.nix
      ../../modules/system/lsfg-vk-dev.nix
      ../../modules/system/boot-nex.nix
      ../../modules/system/environment-nex.nix
      ../../modules/hardware/nvidia.nix
      ../../modules/hardware/legion.nix
      ../../modules/hardware/atlas-air.nix
      ../../modules/hardware/touchpad.nix
      ../../modules/programs/gaming
      ../../modules/programs/cachyos-tools.nix
      ../../modules/programs/ideamaker.nix
      ../../modules/users/mortiferus.nix
      ../../modules/home/mortiferus
    ];

  networking.hostName = "nex";

  system.stateVersion = "26.05"; 
  
}
