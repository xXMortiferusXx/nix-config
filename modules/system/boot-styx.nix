{ config, pkgs, lib, ... }:

{
  imports = [ ./boot-common.nix ];

  my.btrfs.fileSystems = [ "/" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    "intel_pstate=active"
    "i915.enable_fbc=1"
    "i915.fastboot=1"
  ];

  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" "iTCO_wdt" ];
}
