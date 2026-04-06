{ config, pkgs, lib, ... }:

{
  # ────────────── Grafiktreiber (Hybrid AMD/NVIDIA) ──────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true; 
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # ────────────── LENOVO LEGION PERFORMANCE ──────────────
  # Kernel-Modul für Lüftersteuerung & Power-Profile (Rote LED / Fn+Q)
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];
  boot.kernelModules = [ "lenovo_legion" ];
  
  # Ermöglicht das Umschalten zwischen Power-Profilen (Gaming/Eco)
  services.power-profiles-daemon.enable = true;

  environment.systemPackages = with pkgs; [
    # Korrigierter Paketname:
    lenovo-legion 
  ];
}
