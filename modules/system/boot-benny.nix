# Boot-Konfiguration fuer benny (Intel Ivy Bridge / HD Graphics 4000).
# Aktueller Kernel + intel_pstate; kein GPU-Sonderfall mehr (R9 280 ausgebaut).
{ config, pkgs, lib, ... }:

{
  imports = [ ./boot-common.nix ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    "intel_pstate=active"

    "transparent_hugepage=madvise"
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
  };

  # Watchdog-Module abschalten (iTCO_wdt = Intel-Watchdog).
  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" "iTCO_wdt" ];

  zramSwap.memoryPercent = lib.mkForce 100;
}
