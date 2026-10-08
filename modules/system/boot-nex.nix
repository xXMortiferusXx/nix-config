# Boot-Konfiguration fuer nex (CachyOS-Kernel, x86_64-v3).
# PRIME-Hybrid + amdgpu-Params + ntsync aktiv (siehe nvidia-prime.nix);
# Netz-Tweaks kommen aus cachyos-tuning.nix.
{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ./boot-common.nix ];

  # CachyOS Kernel Overlay (xddxdd) — pkgs.cachyosKernels.* verfügbar machen
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  # latest-x86_64-v3: bore-v3 fehlt im Binary-Cache (sonst lokaler Build).
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;
  # CachyOS-Kernel bringt den "adios" I/O-Scheduler mit -> in cachyos-tuning.nix nutzen.
  tuning.ioScheduler = "adios";
  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" "iTCO_wdt" "sp5100_tco" ];

  # ntsync: DRM-Sync fuer Wayland/VRR.
  boot.kernelModules = [ "ntsync" ];

  boot.kernelParams = [
    "transparent_hugepage=madvise"
    # AMD CPU P-State Treiber (CPU, nicht GPU — bleibt aktiv)
    "amd_pstate=active"
    # NVreg_DynamicPowerManagement nicht hier setzen (nixpkgs macht das bei powerManagement.enable).
    # amdgpu: VRR-MCLK-Switching + Stutter-Mode deaktivieren.
    "amdgpu.dcfeaturemask=0x0"
    "amdgpu.dcdebugmask=0x2"
    # usbcore.old_scheme_first=1: robuster gegen GC7-UAC-Clock-Verlust.
    "usbcore.old_scheme_first=1"
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
  };

  # Legacy-DHCP (dhcpcd) bewusst nicht gesetzt (NetworkManager übernimmt).

  zramSwap.memoryPercent = lib.mkForce 100;
}
