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
      # ../../modules/hardware/wifi-iwlwifi.nix  # deaktiviert zum Testen
      ../../modules/users/backbone.nix
      ../../modules/home/backbone
    ];

  networking.hostName = "styx";
  system.stateVersion = "26.05"; 
}
