{ config, pkgs, ... }:

{
  imports = [ ./environment-common.nix ];

  # Hier könnten später styx-spezifische Variablen rein
  environment.variables = {
    "EDITOR" = "nvim";
  };
}
