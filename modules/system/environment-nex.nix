{ config, pkgs, ... }:

{
  imports = [ ./environment-common.nix ];

  environment.variables = {
    # NVIDIA Shader-Disk-Cache (12 GB) — reduziert Stutter in Spielen
    "__GL_SHADER_DISK_CACHE_SIZE" = "12000000000";
  };
}
