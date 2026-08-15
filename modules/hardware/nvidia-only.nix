# NVIDIA-only Modul fuer nex (ab 2026-08-12)
# Reine dGPU-Ausgabe ohne PRIME/iGPU. Wayland-Optimierungen (GBM, Explicit Sync, VRR).
{ config, pkgs, lib, ... }:

{
  # NVIDIA-only Modus: Keine iGPU/PRIME, reine dGPU-Ausgabe.
  # Wichtig fuer Wayland/Niri: modesetting + open driver + GBM-Backend.

  # Notwendig für die NVIDIA-Firmware
  hardware.enableRedistributableFirmware = true;

  # Nur NVIDIA-Treiber laden
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # Mesa bleibt als System-GL/Vulkan-Infrastruktur (Loader/Layer)
    package = pkgs.mesa;
    package32 = pkgs.pkgsi686Linux.mesa;
    extraPackages = with pkgs; [
      # Vulkan-Infrastruktur
      vulkan-loader
      vulkan-tools
      vulkan-extension-layer

      # Native Videobeschleunigung für NVIDIA (Firefox/Discord/Chromium)
      nvidia-vaapi-driver
      libva-utils

      # vkBasalt Vulkan-Post-Processing-Layer
      vkbasalt
    ];
  };

  # CachyOS modprobe.d/nvidia.conf: NVIDIA Memory Clearing deaktivieren (Performance)
  boot.extraModprobeConfig = ''
    options nvidia NVreg_InitializeSystemMemoryAllocations=0
  '';

  hardware.nvidia = {
    # Essential für Wayland/KMS
    modesetting.enable = true;
    nvidiaSettings = true;

    # Moderner Open-Source-Kernel-Modul (Open-GPU-Kernel-Modules)
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    # Power Management: bei NVIDIA-only kein feingranuliertes PM nötig
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    # Kein PRIME-Block — reine dGPU-Ausgabe
  };

  # Wayland-spezifische NVIDIA-Optimierungen
  environment.sessionVariables = {
    # GBM-Backend für NVIDIA (Wayland-Compositor + Apps)
    "GBM_BACKEND" = "nvidia-drm";
    # GLX Vendor für korrekte NVIDIA-Nutzung unter Wayland/XWayland
    "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
    # VRR/G-Sync erlauben
    "__GL_VRR_ALLOWED" = "1";
    # Electron/Chromium Apps nativ auf Wayland
    "NIXOS_OZONE_WL" = "1";
    # VA-API Treiber für NVIDIA (Hardware-Decoding)
    "LIBVA_DRIVER_NAME" = "nvidia";
    # VDPAU fallback auf NVIDIA
    "VDPAU_DRIVER" = "nvidia";
  };
}
