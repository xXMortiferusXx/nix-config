# Boot-Konfiguration fuer nex (standard latest kernel)
# Keine AMD-iGPU-Parameter mehr (NVIDIA-only seit 2026-08-12).
# Kernel auf standard latest umgestellt (2026-08-13) — xanmod entfernt.
# scx_bpfland bleibt aktiv (unterstuetzt von sched-ext im Standard-Kernel).
{ config, pkgs, lib, ... }:

{
  imports = [ ./boot-common.nix ];

  my.btrfs.fileSystems = [ "/" "/gaming" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "ntsync" ];
  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" "iTCO_wdt" "sp5100_tco" ];

  boot.kernelParams = [
    "transparent_hugepage=madvise"
    # AMD CPU P-State Treiber (CPU, nicht GPU — bleibt aktiv)
    "amd_pstate=active"
    # Kein amdgpu-Parameter mehr (iGPU deaktiviert / nicht genutzt)
    # Kein NVreg_DynamicPowerManagement (NVIDIA läuft permanent)
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
  };

  zramSwap.memoryPercent = lib.mkForce 100;

  systemd.services.scx-scheduler = {
    description = "SCX bpfland Scheduler (Auto-Modus)";
    after = [ "systemd-modules-load.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.scx.full}/bin/scx_bpfland";
      Restart = "on-failure";
      StandardOutput = "journal";
    };
  };
}
