{ config, pkgs, lib, inputs, ... }:

let
  pkgsList = import ./packages.nix pkgs;
in {
  home-manager.users.backbone = { config, ... }: {
    imports = [
      inputs.noctalia.homeModules.default
      ./config.nix
      ./autostart.nix
    ];

    programs.home-manager.enable = true;
    programs.noctalia.enable = true;
    programs.noctalia.systemd.enable = true;

    home.packages = pkgsList;
    home.username = "backbone";
    home.homeDirectory = "/home/backbone";
    home.stateVersion = "26.05";
  };
}
