# Umgebungs-Konfiguration fuer lion-pc
# AMD-only → kein CUDA, keine NVIDIA-Shader-Cache-Env (siehe environment-nex.nix)
{ config, pkgs, ... }:

{
  imports = [ ./environment-common.nix ];

  # Kein CUDA auf AMD-only-System
  nixpkgs.config.cudaSupport = false;

  environment.variables = {
    "EDITOR" = "nvim";
  };
}