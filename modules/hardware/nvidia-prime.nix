# NVIDIA PRIME-Hybrid für nex (Advanced Optimus, Lenovo Legion 5).
# BIOS: "Switchable Graphics" aktiv. iGPU (amdgpu, PCI:6:0:0) fährt das
# Display, dGPU (NVIDIA, PCI:1:0:0) wird per `nvidia-offload` zugeschaltet.
{ config, pkgs, lib, ... }:

{
  hardware.enableRedistributableFirmware = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # Mesa bleibt System-GL/Vulkan-Infrastruktur (Loader/Layer)
    package = pkgs.mesa;
    package32 = pkgs.pkgsi686Linux.mesa;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-tools
      vulkan-extension-layer
      nvidia-vaapi-driver
      libva-utils
      vkbasalt
    ];
  };

  # Kein lib.mkForce: die Option aus legion.nix ("iwlmvm power_scheme=1")
  # muss erhalten bleiben.
  boot.extraModprobeConfig = ''
    options nvidia NVreg_TemporaryFilePath=/var/tmp
    options nvidia NVreg_InitializeSystemMemoryAllocations=0
  '';

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    powerManagement.enable = true;
    powerManagement.finegrained = true; # nur mit PRIME erlaubt (NixOS-Assertion)

    # Dynamic Boost 2.0: nvidia-powerd hebt die dGPU unter Last über die
    # 115-W-Basis (bis ~128 W).
    dynamicBoost.enable = true;

    prime = {
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
      offload = {
        enable = true;
        enableOffloadCmd = false; # ersetzt durch eigenes Skript unten
      };
    };
  };

  # Eigenes Offload-Skript: setzt zusätzlich VK_DRIVER_FILES. Das NVIDIA-Paket
  # bringt hier keine Vulkan-Layer mit, sonst wählt der Loader die iGPU (RADV).
  # Nicht global setzen — Umbriel rendert auf der iGPU.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      export VK_DRIVER_FILES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json
      exec "$@"
    '')
  ];

  # VRAM-Heap-Fix (GLVidHeapReuseRatio=0) für bekannte Electron-/GPU-Apps.
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-vram-fix.json".text = builtins.toJSON {
    rules = [
      { pattern = { feature = "procname"; matches = "umbriel"; }; profile = "No VidMem Reuse"; }
      { pattern = { feature = "procname"; matches = "steamwebhelper"; }; profile = "No VidMem Reuse"; }
      { pattern = { feature = "procname"; matches = "Discord"; }; profile = "No VidMem Reuse"; }
      { pattern = { feature = "procname"; matches = "vesktop"; }; profile = "No VidMem Reuse"; }
      { pattern = { feature = "procname"; matches = "heroic"; }; profile = "No VidMem Reuse"; }
    ];
    profiles = [{
      name = "No VidMem Reuse";
      settings = [{ key = "GLVidHeapReuseRatio"; value = 0; }];
    }];
  };

  environment.sessionVariables = {
    "__GL_VRR_ALLOWED" = "1"; # VRR für prime-run NVIDIA-GL-Spiele
    "NIXOS_OZONE_WL" = "1"; # Electron/Chromium nativ auf Wayland
    "LIBVA_DRIVER_NAME" = "radeonsi"; # Compositor-GPU ist die iGPU
    "VDPAU_DRIVER" = "radeonsi";
  };
}
