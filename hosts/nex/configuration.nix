{ config, pkgs, inputs, ... }:

let
  # GameDAC-Knacken-Fix (Titelwechsel): ASM-Filter-Ketten mit
  # "node.pause-on-idle = false" erzeugen, damit die HeSuVi/Sonar-Convolution
  # beim Stream-Neustart nicht in "idle" faellt und ihren Zustand behaelt
  # (kein Transient/Knacken am Liedanfang). Patch aufs Upstream-Paket,
  # damit er jede ASM-Regeneration uebersteht.
  arctis-sound-manager = inputs.arctis-sound-manager.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      ${pkgs.python3}/bin/python3 ${../../scripts/asm-pause-on-idle.py} src/arctis_sound_manager/sonar_to_pipewire.py
    '';
  });
in
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
  services.arctis-sound-manager.package = arctis-sound-manager;

  system.stateVersion = "26.05"; 
  
}
