{ config, pkgs, lib, ... }:

{
  # Controller & Eingabegeräte
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
      vulkan-loader
      vulkan-tools
      vulkan-validation-layers
      vulkan-extension-layer
      nvidia-vaapi-driver
    ];
  };
  
  services.fwupd.enable = true;
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.enableRedistributableFirmware = true;
  services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;

  # --- DEIN AKTUELLER KERNEL-BLOCK (Eins zu Eins) ---
  boot.kernelParams = [ 
    # --- DEINE GAMING PERFORMANCE (Behalten!) ---
    "preempt=full" 
    "split_lock_detect=off"        # Verhindert Performance-Einbrüche bei alten Engines
    "transparent_hugepage=madvise" # Optimiert Speichernutzung für Gaming
    "amd_pstate=active"            # Volle Kontrolle über die AMD-Kerne
    "amdgpu.sg_display=0"          # Verhindert Stottern (Hybrid-Graphics Fix)
    "nvidia.NVreg_DynamicPowerManagement=0x02"  # Besseres Powermanagement
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Energie-Optimierung für Deep Sleep (D3Cold)
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

  # Lenovo Legion Performance
  boot.extraModulePackages = [ 
    config.boot.kernelPackages.lenovo-legion-module
    config.boot.kernelPackages.zenergy  # Hier lag der Fehler
  ];
 
 services.power-profiles-daemon.enable = true;
  environment.systemPackages = with pkgs; [
    lenovo-legion 
  ];
}
