{ config, pkgs, lib, ... }:

{
  boot.initrd.kernelModules = [ "i915" ];
  hardware.enableRedistributableFirmware = true;
  
  # Grafiktreiber für Intel
  services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # QuickSync & Hardware Video Codecs
      libvdpau-va-gl
      intel-vaapi-driver # Ersatz für den veralteten libva-intel-driver
      intel-compute-runtime # OpenCL
    ];
  };

  # Energie sparen bei Intel iGPUs
  environment.variables = {
    "VDPAU_DRIVER" = "va_gl";
    "LIBVA_DRIVER_NAME" = "iHD";
  };
}
