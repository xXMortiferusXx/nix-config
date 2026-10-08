# Boot-Konfiguration fuer lion-pc (CachyOS-Kernel).
# AMD Ryzen (Zen1) + Radeon RX 580; adios-Scheduler via cachyos-tuning.nix.
{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ./boot-common.nix ];

  # CachyOS Kernel Overlay (xddxdd) — pkgs.cachyosKernels.* verfügbar machen
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
  # CachyOS-Kernel bringt den "adios" I/O-Scheduler mit -> in cachyos-tuning.nix nutzen.
  tuning.ioScheduler = "adios";
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