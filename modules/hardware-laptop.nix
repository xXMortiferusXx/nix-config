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
    libvdpau-va-gl      # Brücke für Video-Beschleunigung
    libva-vdpau-driver   # Der neue Name für vaapiVdpau
    libva-utils          # Sehr nützlich: ermöglicht den Befehl 'vainfo' zum Testen
  ];
};

 services.xserver.videoDrivers = [ "nvidia" ];

hardware.nvidia = {
    # Modesetting ist für Wayland/Niri zwingend erforderlich [cite: 59, 76]
    modesetting.enable = true;

    # Nutzt die Open-Source Kernel-Module von NVIDIA (empfohlen für moderne Karten) [cite: 59, 76]
    open = true;

    # Nutzt das stabile Treiber-Paket passend zu deinem Zen-Kernel [cite: 60]
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # --- ENERGIE-OPTIMIERUNG FÜR ~9W IDLE ---
    # Fine-grained Power Management erlaubt der GPU den Deep Sleep (D3Cold) 
    powerManagement.enable = false; 
    powerManagement.finegrained = true; 

    # Ermöglicht Dynamic Boost zur intelligenten TDP-Verteilung zwischen CPU und GPU 
    dynamicBoost.enable = true;

    prime = {
      # Deine spezifischen Bus-IDs für das Legion Laptop [cite: 60]
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
      
      # Offload-Modus: Die NVIDIA-Karte schläft, bis sie explizit gerufen wird [cite: 61]
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };
  # LENOVO LEGION PERFORMANCE
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];
  services.power-profiles-daemon.enable = true;

  environment.systemPackages = with pkgs; [
    lenovo-legion 
  ];
}
