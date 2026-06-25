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
      ../../modules/home/backbone
    ];

  networking.hostName = "styx";
  system.stateVersion = "26.05"; 
}
