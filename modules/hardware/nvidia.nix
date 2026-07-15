{ config, pkgs, lib, ... }:

{
  # Lädt AMD-Grafik extrem früh für flüssiges Booten (Sehr gut!)
  boot.initrd.kernelModules = [ "amdgpu" ];
  
  # Notwendig für die NVIDIA-Firmware
  hardware.enableRedistributableFirmware = true;
  
  # Nur "nvidia" eintragen, amdgpu wird bei PRIME automatisch geladen
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    package = pkgs.mesa;
    package32 = pkgs.pkgsi686Linux.mesa;
    extraPackages = with pkgs; [
      # Wichtige Systemkomponenten für Vulkan-Spiele
      vulkan-loader
      vulkan-tools
      vulkan-extension-layer
      
      # Native Videobeschleunigung für NVIDIA (Firefox/Discord)
      nvidia-vaapi-driver
      libva-utils
    ];
  };

  # CachyOS modprobe.d/nvidia.conf: NVIDIA Memory Clearing deaktivieren (Performance)
  boot.extraModprobeConfig = ''
    options nvidia NVreg_InitializeSystemMemoryAllocations=0
  '';

  hardware.nvidia = {
    # Übernimmt Treiber 595/610 automatisch, kann zur Sicherheit aber bleiben
    modesetting.enable = true; 
    nvidiaSettings = true;
    
    # Perfekt: Nutzt die moderne Open-Source-Architektur
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    # Essentiell für fehlerfreien Standby & Energiesparen
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    # PRIME-Konfiguration für Laptops
    prime = {
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";

      # Aktiviert den Offload-Modus (NVIDIA schläft, bis sie gerufen wird)
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };
}
