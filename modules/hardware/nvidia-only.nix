# NVIDIA-only Modul: reine dGPU-Ausgabe ohne PRIME/iGPU (Stand 2026-08-12).
#
# STATUS: aktuell von KEINEM Host importiert. nex nutzt seit 2026-09-26
# wieder modules/hardware/nvidia-prime.nix (PRIME-Hybrid, Advanced Optimus).
# Dieses Modul bleibt bewusst als Rollback-Pfad erhalten: Wer auf nex wieder
# reine dGPU-Ausgabe ohne Hybrid will, tauscht in hosts/nex/configuration.nix
# den Import nvidia-prime.nix -> nvidia-only.nix.
#
# ACHTUNG beim Wiedereinschalten: boot-nex.nix setzt inzwischen wieder
# amdgpu-Parameter, ntsync und nvidia.NVreg_DynamicPowerManagement, die zur
# PRIME-Hybrid-Konfiguration gehoeren. Fuer echtes NVIDIA-only muessen die
# dort ebenfalls bereinigt werden.
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

      # Native Videobeschleunigung für NVIDIA (Firefox/Discord/Chromium)
      nvidia-vaapi-driver
      libva-utils

      # vkBasalt Vulkan-Post-Processing-Layer
      vkbasalt
    ];
  };

  # TemporaryFilePath fuer PreserveVideoMemoryAllocations (Suspend/Resume)
  #
  # ReBAR: NICHT explizit gesetzt. Der Treiber aktiviert Resizable BAR auf
  # diesem Notebook von selbst; verifiziert am 2026-09-26:
  #   nvidia-smi -q            -> BAR1 Memory Usage Total: 8192 MiB
  #   vulkaninfo               -> NVIDIA memoryTypes[5] heapIndex 0,
  #                               propertyFlags 0x0007 (DEVICE_LOCAL |
  #                               HOST_VISIBLE | HOST_CACHED)
  # Ein frueherer Kommentar deutete BAR0 = 16 MB als "ReBAR aus" — das war
  # eine Fehldeutung: BAR0 bleibt auch bei aktivem ReBAR klein, das grosse
  # BAR kommt als separates PCI-BAR (0xfa00000000, 8192 MB).
  boot.extraModprobeConfig = ''
    options nvidia NVreg_TemporaryFilePath=/var/tmp
  '';

  hardware.nvidia = {
    # Essential für Wayland/KMS
    modesetting.enable = true;
    nvidiaSettings = true;

    # Moderner Open-Source-Kernel-Modul (Open-GPU-Kernel-Modules)
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    # Power Management: grundsaetzlich aktiviert.
    # Finegrained geht nicht ohne PRIME-Offload (NixOS-Assertion).
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    # Kein PRIME-Block — reine dGPU-Ausgabe
  };

  # NVIDIA VRAM-Heap-Fix: GLVidHeapReuseRatio=0
  # Treiber gibt freigegebenes VRAM nicht zurueck an den Pool
  # Siehe: https://github.com/niri-wm/niri/wiki/Nvidia#high-vram-usage-fix
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-vram-fix.json".text = builtins.toJSON {
    rules = [
      # Umbriel (primäre Session, wlroots)
      {
        pattern = {
          feature = "procname";
          matches = "umbriel";
        };
        profile = "No VidMem Reuse";
      }
      # Electron Apps (VRAM-Freezing bekannt)
      {
        pattern = {
          feature = "procname";
          matches = "steamwebhelper";
        };
        profile = "No VidMem Reuse";
      }
      {
        pattern = {
          feature = "procname";
          matches = "Discord";
        };
        profile = "No VidMem Reuse";
      }
      {
        pattern = {
          feature = "procname";
          matches = "vesktop";
        };
        profile = "No VidMem Reuse";
      }
      {
        pattern = {
          feature = "procname";
          matches = "heroic";
        };
        profile = "No VidMem Reuse";
      }
    ];
    profiles = [{
      name = "No VidMem Reuse";
      settings = [{
        key = "GLVidHeapReuseRatio";
        value = 0;
      }];
    }];
  };

  # Wayland-spezifische NVIDIA-Optimierungen
  environment.sessionVariables = {
    # GBM-Backend für NVIDIA (Wayland-Compositor + Apps)
    "GBM_BACKEND" = "nvidia-drm";
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
