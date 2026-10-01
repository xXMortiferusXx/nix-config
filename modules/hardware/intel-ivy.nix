# Intel-Onboard-Grafik fuer benny (i5-3xxx / Ivy Bridge, HD Graphics 4000).
#
# WICHTIG: Ivy Bridge ist Gen7. VA-API laeuft dort ueber den Legacy-Treiber
# i965 (intel-vaapi-driver) — NICHT ueber iHD/intel-media-driver, die erst
# ab Gen9 (Skylake) unterstuetzt werden. Deshalb hier explizit i965.
{ config, pkgs, lib, ... }:

{
  boot.initrd.kernelModules = [ "i915" ];
  hardware.enableRedistributableFirmware = true;

  # Grafiktreiber fuer Intel
  services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver   # i965 (Gen7 / HD 4000): VA-API Hardware-Dekodierung
      libvdpau-va-gl
    ];
  };

  environment.variables = {
    "LIBVA_DRIVER_NAME" = "i965";
    "VDPAU_DRIVER" = "va_gl";
  };
}
