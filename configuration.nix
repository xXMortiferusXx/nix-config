{ config, pkgs, inputs, ... }:
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./modules/system.nix
    ./modules/hardware-laptop.nix
    ./modules/users.nix
    ./modules/desktop.nix
    ./modules/audio.nix
    ./modules/gaming.nix
    ./modules/alias.nix
    ./modules/fish.nix
    ./modules/kitty.nix
    ./modules/services/noctalia.nix
    ./modules/home.nix
  ];

  system.stateVersion = "25.11";
}
