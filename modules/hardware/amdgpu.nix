# Grafiktreiber für AMD (Radeon RX 580 8GB / GCN-Polaris)
# Mesa-RADV (Vulkan) + radeonsi (VA-API/VDPAU)
{ config, pkgs, lib, ... }:

{
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.enableRedistributableFirmware = true;

  # Grafiktreiber für AMD
  services.xserver.videoDrivers = lib.mkForce [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # VA-API für Hardware-Video-Dekodierung (GCN: radeonsi liefert das)
    extraPackages = with pkgs; [
      libva
    ];
    extraPackages32 = with pkgs; [
      libva
    ];
  };

  environment.variables = {
    "LIBVA_DRIVER_NAME" = "radeonsi";
    "VDPAU_DRIVER" = "radeonsi";
  };
}