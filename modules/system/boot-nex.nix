# Boot-Konfiguration fuer nex (Standard-Latest Kernel)
# PRIME-Hybrid seit 2026-09-26 wieder aktiv (siehe modules/hardware/nvidia-prime.nix):
# amdgpu-Kernelparameter + ntsync sind zurueck.
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

  # ntsync: DRM-Sync-Mechanismus fuer Wayland/VRR (NVIDIA-only hatte es nicht,
  # die alte PRIME-Config schon). Verbessert Tear-/Sync-Verhalten unter Umbriel.
  boot.kernelModules = [ "ntsync" ];

  boot.kernelParams = [
    "transparent_hugepage=madvise"
    # AMD CPU P-State Treiber (CPU, nicht GPU — bleibt aktiv)
    "amd_pstate=active"
    # Hinweis: nvidia.NVreg_DynamicPowerManagement=0x02 wird NICHT hier gesetzt.
    # nixpkgs traegt es bei powerManagement.enable = true automatisch in
    # /etc/modprobe.d/nixos.conf ein (zusammen mit PreserveVideoMemoryAllocations
    # und UseKernelSuspendNotifiers). Ein KernelParam waere ein Duplikat.
    # amdgpu: VRR-assoziiertes MCLK-Switching + Stutter-Mode deaktivieren
    # (Snow-Blitz-Stottern unter Last auf der iGPU, aus alter PRIME-Config).
    "amdgpu.dcfeaturemask=0x0"
    "amdgpu.dcdebugmask=0x2"
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
  };

  # Legacy-DHCP (dhcpcd) ist bei aktivem NetworkManager überflüssig — nixpkgs
  # erzwingt im NM-Modul selbst useDHCP=false ("managed entirely by
  # NetworkManager"). Explizite Option daher bewusst NICHT gesetzt (wäre nur
  # Dokumentation und würde suggerieren, auf lion-pc/styx fehle etwas).

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
