{ config, pkgs, lib, ... }:

{
  # Distrobox für Container-Apps (z.B. Sidekick via Arch Linux)
  environment.systemPackages = with pkgs; [
    distrobox
    podman
  ];

  # Podman als Backend für Distrobox
  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # Wir wollen nur podman, keinen docker socket
  };
}
