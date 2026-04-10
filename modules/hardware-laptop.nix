{ config, pkgs, lib, ... }:

{
  hardware.uinput.enable = true; 
  hardware.xone.enable = true;
  hardware.xpadneo.enable = true;

  hardware.graphics = {
    enable = true; 
    enable32Bit = true; 
    extraPackages = with pkgs; [
      libvdpau-va-gl
      libva-vdpau-driver
      libva-utils
      # Vulkan & Diagnose direkt hier behalten
      vulkan-loader
      vulkan-tools
      vulkan-validation-layers
      vulkan-extension-layer
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    
    # Auf 'true' für Wayland-Stabilität (Niri/Noctalia)
    powerManagement.enable = true; 
    powerManagement.finegrained = true; 
    dynamicBoost.enable = true;

    prime = {
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };

  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];
}
