# Umgebungs-Konfiguration fuer benny
# Intel CPU + AMD Radeon R9 280 -> kein CUDA
{ config, pkgs, ... }:

{
  imports = [ ./environment-common.nix ];

  nixpkgs.config.cudaSupport = false;

  environment.variables = {
    "EDITOR" = "nvim";
  };
}
