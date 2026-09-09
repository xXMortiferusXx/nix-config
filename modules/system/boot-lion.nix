# Boot-Konfiguration fuer lion-pc (Zen Kernel)
# AMD CPU (Ryzen) + AMD Radeon RX 580 8GB.
# Zen Kernel (pkgs.linuxPackages_zen) — Gaming/Desktop-optimiert, immer aktuelle Version.
{ config, pkgs, lib, ... }:

{
  imports = [ ./boot-common.nix ];

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" "iTCO_wdt" "sp5100_tco" ];

  boot.kernelParams = [
    "transparent_hugepage=madvise"
    # AMD P-State NICHT verwenden: Ryzen 1500X (Zen 1) unterstützt es nicht.
    # Kernel fällt sonst auf acpi-cpufreq zurueck; explizit deaktivieren,
    # damit power-profiles-daemon das performance-Profil anbietet.
    "amd_pstate=disable"
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
  };

  # ZRAM 100% wie auf nex (kein klassischer Swap)
  zramSwap.memoryPercent = lib.mkForce 100;
}