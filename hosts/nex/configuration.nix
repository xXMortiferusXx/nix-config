{ config, ... }:

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
      ../../modules/hardware/gamedac.nix
      ../../modules/programs/gaming
      ../../modules/programs/cachyos-tools.nix
      
      ../../modules/users/mortiferus.nix
      ../../modules/home/mortiferus
      ./config-mounts.nix
    ];

  networking.hostName = "nex";

  # Greeter-Sync (Wallpaper/Farben) passwortlos für den Haupt-User
  services.displayManager.noctalia-greeter.passwordless-sync-users = [ "mortiferus" ];

  system.stateVersion = "26.05"; 
  
}
