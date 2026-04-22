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
    ./modules/speedtest.nix
    ./modules/nix-tools.nix
  ];

  # stateVersion nur einmal hier definieren (wurde aus system.nix entfernt)
  system.stateVersion = "25.11";
}
