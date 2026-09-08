# Boot-Konfiguration fuer nex (Zen Kernel)
# Keine AMD-iGPU-Parameter mehr (NVIDIA-only seit 2026-08-12).
# Zen Kernel (pkgs.linuxPackages_zen) — Gaming/Desktop-optimiert, immer aktuelle Version.
{ config, pkgs, lib, ... }:

{
  imports = [ ./boot-common.nix ];

  boot.kernelPackages = pkgs.linuxPackages_zen;
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

  # scx_bpfland deaktiviert — Zen-Kernel wird pur getestet
  # systemd.services.scx-scheduler = {
  #   description = "SCX bpfland Scheduler (Gaming-Modus)";
  #   after = [ "systemd-modules-load.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.scx.full}/bin/scx_bpfland -m all";
  #     Restart = "on-failure";
  #     StandardOutput = "journal";
  #   };
  # };
}
