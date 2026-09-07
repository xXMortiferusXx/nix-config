# Boot-Konfiguration fuer lion-pc (CachyOS Kernel)
# AMD CPU (Ryzen) + AMD Radeon RX 580 8GB.
# CachyOS Kernel via xddxdd/nix-cachyos-kernel — bessere Latenz + Performance fuer Gaming.
{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ./boot-common.nix ];

  # CachyOS Kernel Overlay (xddxdd) — pkgs.cachyosKernels.* verfügbar machen
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" "iTCO_wdt" "sp5100_tco" ];

  boot.kernelParams = [
    "transparent_hugepage=madvise"
    # AMD CPU P-State Treiber (ZEN-basiert)
    "amd_pstate=active"
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
  };

  # ZRAM 100% wie auf nex (kein klassischer Swap)
  zramSwap.memoryPercent = lib.mkForce 100;
}