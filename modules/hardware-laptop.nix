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
      # --- DEINE BESTEHENDEN PAKETE (Video-Beschleunigung) ---
      libvdpau-va-gl       # Brücke für Video-Beschleunigung 
      libva-vdpau-driver   # VA-API zu VDPAU Treiber 
      libva-utils          # Ermöglicht 'vainfo' 

      # --- NEU: VULKAN & DIAGNOSE (CachyOS-Style) ---
      vulkan-loader
      vulkan-tools         # Für vkcube und vulkaninfo
      vulkan-validation-layers
      vulkan-extension-layer
    ];
  };

 services.xserver.videoDrivers = [ "nvidia" ];

hardware.nvidia = {
    # Modesetting ist für Wayland/Niri zwingend erforderlich
    modesetting.enable = true;
    nvidiaSettings = true; # Korrigiert: Aktiviert Management-Tools & Bibliotheken

    # Nutzt die Open-Source Kernel-Module von NVIDIA (empfohlen für moderne Karten)
    open = true;

    # Nutzt das stabile Treiber-Paket passend zu deinem Zen-Kernel
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # --- ENERGIE-OPTIMIERUNG FÜR ~9W IDLE ---
    # Fine-grained Power Management erlaubt der GPU den Deep Sleep (D3Cold) 
    powerManagement.enable = true; # Korrigiert: Muss auf true für finegrained
    powerManagement.finegrained = true; #

    # Ermöglicht Dynamic Boost zur intelligenten TDP-Verteilung zwischen CPU und GPU
    dynamicBoost.enable = true;

    prime = {
      # Deine spezifischen Bus-IDs für das Legion Laptop
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
      
      # Offload-Modus: Die NVIDIA-Karte schläft, bis sie explizit gerufen wird
      offload = {
        enable = true;
        enableOffloadCmd = true; #
      };
    };
  };
  # LENOVO LEGION PERFORMANCE
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ]; #
  services.power-profiles-daemon.enable = true; #
  environment.systemPackages = with pkgs; [
    lenovo-legion #
  ];
}
