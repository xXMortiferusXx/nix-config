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
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };

  # ────────────── LENOVO LEGION PERFORMANCE ──────────────
  # Paket stellt das Modul bereit. Wir lassen den manuellen 'kernelModules' 
  # Eintrag weg, da dieser beim Boot oft zu Fehlmeldungen führt, 
  # wenn das Modul erst später vom Kernel erkannt wird.
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];
  
  services.power-profiles-daemon.enable = true;

  environment.systemPackages = with pkgs; [
    lenovo-legion 
  ];
}
