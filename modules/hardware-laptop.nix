{ config, pkgs, lib, ... }:

{
 
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
    modesetting.enable = true;
    open = true; 
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
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
