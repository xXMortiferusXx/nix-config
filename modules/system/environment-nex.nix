{ config, pkgs, ... }:

{
  imports = [ ./environment-common.nix ];

  environment.variables = {
    "__GL_SHADER_DISK_CACHE_SIZE" = "12000000000";
    "__GL_THREADED_OPTIMIZATIONS" = "1";
    "__GL_SYNC_TO_VBLANK" = "0";
  };
}
