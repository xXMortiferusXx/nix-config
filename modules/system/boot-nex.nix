# Boot-Konfiguration fuer nex (Standard-Latest Kernel)
# Keine AMD-iGPU-Parameter mehr (NVIDIA-only seit 2026-08-12).
# CachyOS Kernel via xddxdd/nix-cachyos-kernel temporaer deaktiviert:
# NVIDIA 615 scheitert am CachyOS __to_hwgpio-Patch. Overlay bleibt aktiv,
# damit bei einem CachyOS-Kernel-Update einfach die Zeile wieder aktiviert
# werden kann (siehe unten).
# Hinweis: der "adios" I/O-Scheduler existiert nur im CachyOS-Kernel —
# in cachyos-tuning.nix daher auf "kyber" umgestellt.
{ config, pkgs, lib, inputs, ... }:

{
  imports = [ ./boot-common.nix ];

  # CachyOS Kernel Overlay (xddxdd) — pkgs.cachyosKernels.* verfügbar machen
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  # CachyOS-Kernel deaktiviert (Fallback bei Kernel-Update): Zeile wieder aktivieren
  # boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
  boot.kernelPackages = pkgs.linuxPackages_latest;
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
