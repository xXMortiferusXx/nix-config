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
    ./modules/fish.nix
    ./modules/kitty.nix
    ./modules/services/noctalia.nix
    ./modules/home.nix
    ./modules/tools/speedtest.nix
    ./modules/tools/nix-tools.nix
    ./modules/tools/cache-check.nix
  ];

  # stateVersion nur einmal hier definieren
  system.stateVersion = "25.11";
}
