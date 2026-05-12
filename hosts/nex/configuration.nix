{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ./disk-config.nix
      ./disko-gaming.nix
      ../../modules/system/common.nix
      ../../modules/system/boot-nex.nix
      ../../modules/system/environment-nex.nix
      ../../modules/hardware/nvidia.nix
      ../../modules/hardware/legion.nix
      ../../modules/hardware/atlas-air.nix
      ../../modules/programs/gaming.nix
      ../../modules/users/mortiferus.nix
      ../../modules/home/mortiferus.nix
    ];

  networking.hostName = "nex";

  environment.systemPackages = with pkgs; [
    nvtopPackages.full
  ];

  system.stateVersion = "25.11"; 
}
