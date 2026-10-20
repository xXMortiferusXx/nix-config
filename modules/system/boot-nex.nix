# Boot-Konfiguration fuer nex (Latest-Kernel).
# PRIME-Hybrid + amdgpu-Params + ntsync aktiv (siehe nvidia-prime.nix);
# Netz-Tweaks kommen aus cachyos-tuning.nix.
{ config, pkgs, lib, ... }:

{
  imports = [ ./boot-common.nix ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
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
