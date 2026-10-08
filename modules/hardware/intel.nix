# Intel-Onboard-Grafik (modesetting) mit VA-API/iHD, QuickSync und OpenCL.
{ config, pkgs, lib, ... }:

{
  boot.initrd.kernelModules = [ "i915" ];
  hardware.enableRedistributableFirmware = true;
  
  services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # QuickSync/HW-Codecs
      libvdpau-va-gl
      intel-vaapi-driver
      intel-compute-runtime # OpenCL
    ];
  };

  environment.variables = {
    "VDPAU_DRIVER" = "va_gl";
    "LIBVA_DRIVER_NAME" = "iHD";
  };
}
