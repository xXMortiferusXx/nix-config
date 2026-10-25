# Host: nex (Gaming-Laptop, NVIDIA Prime/Optimus).
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
      ../../modules/hardware/nvidia-prime.nix
      ../../modules/hardware/legion.nix
      ../../modules/hardware/touchpad.nix
      ../../modules/hardware/audio-gc7.nix
      ../../modules/programs/gaming
      ../../modules/programs/cachyos-tools.nix
      ../../modules/programs/zink-run.nix
      ../../modules/users/mortiferus.nix
      ../../modules/home/mortiferus
      ./config-mounts.nix
    ];

  networking.hostName = "nex";

  # Greeter-Sync (Wallpaper/Farben) passwortlos für den Haupt-User
  services.displayManager.noctalia-greeter.passwordlessSyncUsers = [ "mortiferus" ];

  # sched_ext: interaktiver Desktop-/Gaming-Scheduler. 6C/12T (Zen 3), kein Hybrid.
  # Slice-/Lag-Defaults bleiben (bpfland ist darauf abgestimmt), zusaetzlich
  # bevorzugt der Scheduler vollstaendig idle Cores. ananicy-cpp bleibt aktiv.
  services.scx = {
    enable = true;
    scheduler = "scx_bpfland";
    extraArgs = [ "--preferred-idle-scan" ];
  };

  system.stateVersion = "26.05"; 
  
}
