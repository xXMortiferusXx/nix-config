# Umgebungs-Konfiguration fuer lion-pc
# AMD-only → kein CUDA, keine NVIDIA-Shader-Cache-Env (siehe environment-nex.nix)
{ config, pkgs, ... }:

{
  imports = [ ./environment-common.nix ];

  nixpkgs.config.cudaSupport = false;

  environment.variables = {
    "EDITOR" = "nvim";
  };
}