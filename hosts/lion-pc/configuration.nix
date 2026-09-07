{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./disk-config.nix
      ../../modules/system/common.nix
      ../../modules/system/boot-lion.nix
      ../../modules/system/environment-lion.nix
      ../../modules/hardware/amdgpu.nix
      ../../modules/programs/gaming/lion.nix
      ../../modules/programs/tools.nix
      ../../modules/services/flatpak-lion.nix
      ../../modules/users/lion.nix
      ../../modules/home/lion
      ./config-mounts.nix
    ];

  networking.hostName = "lion-pc";

  # Sicherheit: sudo-Passwort nötig (Override der common-Vorgabe aus security.nix: false).
  # Bazaar/Flatpak bleibt via Polkit-Regel passwordlos; eine bösartige Flatpak-App
  # kann damit nicht über passwordloses sudo zu Root eskalieren.
  security.sudo.wheelNeedsPassword = lib.mkForce true;

  system.stateVersion = "26.05";
}