{ config, pkgs, ... }:

{
  imports = [ ./environment-common.nix ];

  environment.variables = {
    "__GL_SHADER_DISK_CACHE_SIZE" = "12000000000";
#    "VDPAU_DRIVER" = "va_gl";
 #   "SDL_VIDEODRIVER" = "wayland,x11";
 #   "GDK_BACKEND" = "wayland,x11";
 #   "XDG_SESSION_TYPE" = "wayland";
  };
}
