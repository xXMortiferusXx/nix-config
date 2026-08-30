{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ./disk-config.nix
      ../../modules/system/common.nix
      ../../modules/system/lsfg-vk-dev.nix
      ../../modules/system/boot-nex.nix
      ../../modules/system/environment-nex.nix
      ../../modules/hardware/nvidia-only.nix
      ../../modules/hardware/legion.nix
      ../../modules/hardware/touchpad.nix
      ../../modules/programs/gaming
      ../../modules/programs/cachyos-tools.nix
      ../../modules/programs/ideamaker.nix
      ../../modules/users/mortiferus.nix
      ../../modules/home/mortiferus
      ./config-mounts.nix
    ];

  networking.hostName = "nex";

  # Arctis Sound Manager (SteelSeries GG/Sonar-Ersatz) — verwaltet EQ/ChatMix/Virtual Surround.
  # Nur für nex (Headset); styx läuft ohne.
  services.arctis-sound-manager.enable = true;

  system.stateVersion = "26.05"; 
  
}
