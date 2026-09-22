# Boot-Konfiguration fuer nex (Standard-Latest Kernel)
# Keine AMD-iGPU-Parameter mehr (NVIDIA-only seit 2026-08-12).
# CachyOS Kernel via xddxdd/nix-cachyos-kernel deaktiviert (Overlay bleibt aktiv,
# reaktivierbar):
#   A) NVIDIA 615 scheitert am CachyOS __to_hwgpio-Patch.
#   B) Chaotic-Nyx (linuxPackages_cachyos) waere der passende Kernel, verlangt
#      aber nvidia_cachyos 610.57.04 = Treiber-Downgrade 615 -> 610. Nicht
#      gewollt (kein wahrnehmbarer Kernel-Gewinn vs. linuxPackages_latest),
#      Entscheidung 2026-09-22 beim Garuda-Nyx-Abgleich.
# Unabhängig davon: Netz-Tweaks (cake/fin_timeout/rmem_max) kommen aus dem
# Garuda-Abgleich in cachyos-tuning.nix.
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

  # Legacy-DHCP aus — NetworkManager übernimmt (Garuda-Vergleich)
  networking.useDHCP = lib.mkDefault false;

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
