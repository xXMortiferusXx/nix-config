# Umgebungs-Konfiguration fuer styx (Intel-only, kein CUDA).
{ config, pkgs, ... }:

{
  imports = [ ./environment-common.nix ];

  nixpkgs.config.cudaSupport = false;

  environment.variables = {
    "EDITOR" = "nvim";
  };
}
