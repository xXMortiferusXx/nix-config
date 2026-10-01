# Boot-Konfiguration fuer benny
# Intel CPU (i5-3xxx, Ivy Bridge) mit Intel-Onboard-Grafik (HD Graphics 4000).
#
# Die AMD Radeon R9 280 (GCN 1.0) ist DEFEKT und wurde ausgebaut. Damit ist der
# fruehere GPU-Sonderfall (6.18-LTS-Pin + amdgpu-SI/CIK-Params gegen den
# 6.19er Black-Screen-Bug) hinfaellig -> aktueller Kernel, keine Params.
{ config, pkgs, lib, ... }:

{
  imports = [ ./boot-common.nix ];

  # Aktueller Kernel (kein Sonder-Pin mehr noetig).
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    # Intel CPU: aktiven P-State-Treiber verwenden
    "intel_pstate=active"

    # Wie lion/nex: THP-Verhalten
    "transparent_hugepage=madvise"
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
  };

  # Watchdog-Module abschalten (iTCO_wdt = Intel-Watchdog)
  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" "iTCO_wdt" ];

  # ZRAM 100% wie auf nex/lion (kein klassischer Swap)
  zramSwap.memoryPercent = lib.mkForce 100;
}
