# NVIDIA PRIME-Hybrid fuer nex (reaktiviert 2026-09-26)
#
# AUSGANGSPUNKT: das bis 2026-08-12 genutzte Archiv-Modul
# (archive/modules/hardware/nvidia-prime.nix, rekonstruiert aus Git 064b604^)
# wurde hier in den NVIDIA-only-Zustand (nvidia-only.nix) ueberfuehrt. Diese
# Datei portiert den PRIME-Teil zurueck und mischt ihn mit den inzwischen
# hinzugekommenen, weiterhin gueltigen Einstellungen aus nvidia-only.nix:
#   - 50-vram-fix.json (GL-VRAM-Heap-Fix) bleibt
#   - NVreg_TemporaryFilePath fuer PreserveVideoMemoryAllocations (Suspend/Resume)
#   - vkbasalt / vulkan-tools / nvidia-vaapi-driver / libva-utils bleiben
#   - Wayland-Env (GBM_BACKEND, __GL_VRR_ALLOWED, NIXOS_OZONE_WL, LIBVA/VDPAU)
#
# BIOS-Voraussetzung (Advanced Optimus, Lenovo Legion 5 15ACH6H / 82JU):
#   Configuration -> "Switchable Graphics" aktiv
#   (Optional fuer mehr Headroom: iGPU-UMA-Frame-Buffer (Dedicated Graphics
#    Memory) auf >= 1 GB stellen).
#
# Bus-IDs (historisch, aus 064b604^; nach BIOS-Umstellung mit `lspci` pruefen):
#   NVIDIA dGPU = 01:00.0  -> PCI:1:0:0
#   AMD iGPU     = 06:00.0  -> PCI:6:0:0
{ config, pkgs, lib, ... }:

{
  # Notwendig fuer die NVIDIA-Firmware
  hardware.enableRedistributableFirmware = true;

  # Treiberreihenfolge: NVIDIA dGPU (PRIME-Offload) — amdgpu laeuft ueber PRIME.
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
      # Vulkan-Extension-Layer (z. B. VK_LAYER_MESA_device_select)
      vulkan-extension-layer

      # Native Videobeschleunigung fuer NVIDIA (Firefox/Discord/Chromium)
      nvidia-vaapi-driver
      libva-utils

      # vkBasalt Vulkan-Post-Processing-Layer
      vkbasalt
    ];
  };

  # Modprobe-Optionen fuer NVIDIA.
  # Reihenfolge-Hinweis: es wird bewusst KEIN lib.mkForce verwendet, damit
  # die Option aus legion.nix ("options iwlmvm power_scheme=1") erhalten
  # bleibt. Listen-Werte mehrerer Module werden in Import-Reihenfolge
  # zusammengefuehrt; legion.nix wird nach diesem Modul importiert.
  boot.extraModprobeConfig = ''
    options nvidia NVreg_TemporaryFilePath=/var/tmp
    options nvidia NVreg_InitializeSystemMemoryAllocations=0
  '';

  hardware.nvidia = {
    # Essential fuer Wayland/KMS
    modesetting.enable = true;
    nvidiaSettings = true;

    # Modernes Open-Source-Kernel-Modul (Open-GPU-Kernel-Modules)
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    # Power Management mit PRIME-Offload: finegrained ist erst mit PRIME erlaubt
    # (NixOS-Assertion), in NVIDIA-only war es darum "false".
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    # PRIME-Konfiguration fuer Laptops (Advanced Optimus / Hybrid)
    prime = {
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";

      # NVIDIA schlaeft, bis sie von prime-run / Offload-Cmd aufgeweckt wird
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };

  # NVIDIA VRAM-Heap-Fix: GLVidHeapReuseRatio=0
  # Treiber gibt freigegebenes VRAM nicht zurueck an den Pool
  # Siehe: https://github.com/niri-wm/niri/wiki/Nvidia#high-vram-usage-fix
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-vram-fix.json".text = builtins.toJSON {
    rules = [
      {
        pattern = {
          feature = "procname";
          matches = "umbriel";
        };
        profile = "No VidMem Reuse";
      }
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

  # Wayland/NVIDIA-Optimierungen
  # Anmerkung Hybrid: Der Compositor (Umbriel) laeuft jetzt auf der AMD-iGPU,
# die NVIDIA wird nur per PRIME-Offload fuer Games/App-Starts angesprochen.
  environment.sessionVariables = {
    # VRR/G-Sync: wirkt auf per prime-run gestartete NVIDIA-GL-Spiele
    "__GL_VRR_ALLOWED" = "1";
    # Electron/Chromium Apps nativ auf Wayland
    "NIXOS_OZONE_WL" = "1";
    # Desktop-Videobeschleunigung laeuft ueber die Compositor-GPU (amdgpu).
    # "nvidia" waere hier falsch: der Compositor hat keinen NVIDIA-Render-Node.
    "LIBVA_DRIVER_NAME" = "radeonsi";
    "VDPAU_DRIVER" = "radeonsi";
  };
  # Hinweis: "GBM_BACKEND=nvidia-drm" wurde entfernt. Es war fuer die reine
  # dGPU-Ausgabe noetig, erzwingt im Hybrid aber den NVIDIA-Backend auf einem
  # System, dessen Primaer-Geraet die AMD-iGPU ist (Gefahr: schwarzer Bildschirm
  # durch falsche GBM-Buffer-Allokation). Mesa waehlt das Backend jetzt selbst
  # passend zum jeweiligen DRM-Device.
}
