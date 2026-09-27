# Boot-Konfiguration fuer lion-pc (CachyOS Kernel)
# AMD CPU (Ryzen) + AMD Radeon RX 580 8GB.
# CachyOS Kernel via xddxdd/nix-cachyos-kernel — bessere Latenz + Performance,
# bringt den "adios" I/O-Scheduler mit (ff. udev-Regel in cachyos-tuning.nix).
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

  # "bfq" fest laden: die udev-Regel in cachyos-tuning.nix weist rota-
  # tions-Geraeten (künftige SATA-HDD) bfq zu, aber bfq ist ein Modul
  # (bfq.ko.xz) und haengt sonst am Autoload-Alias "bfq-iosched".
  # Auf lion (Desktop) ist eine HDD realistisch, deshalb fest geladen.
  # nex/styx brauchen das nicht: nex hat nur NVMe, styx laeuft auf Zen.
  boot.kernelModules = [ "bfq" ];

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