# Boot-Konfiguration fuer lion-pc (Latest-Kernel).
# AMD Ryzen (Zen1) + Radeon RX 580; I/O-Scheduler via cachyos-tuning.nix (kyber).
{ config, pkgs, lib, ... }:

{
  imports = [ ./boot-common.nix ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" "iTCO_wdt" "sp5100_tco" ];

  # bfq fest laden: udev-Regel weist HDDs bfq zu, sonst Autoload-Problem.
  boot.kernelModules = [ "bfq" ];

  boot.kernelParams = [
    "transparent_hugepage=madvise"
    # amd_pstate=disable: Ryzen 1500X (Zen1) kann es nicht (sonst kein performance-Profil).
    "amd_pstate=disable"
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
  };

  zramSwap.memoryPercent = lib.mkForce 100;
}