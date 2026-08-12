{ config, pkgs, ... }:

{
  imports = [ ./environment-common.nix ];

  # Kein CUDA auf Intel-only-System
  nixpkgs.config.cudaSupport = false;

  environment.variables = {
    "EDITOR" = "nvim";
  };
}
