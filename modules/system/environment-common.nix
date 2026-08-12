{ config, pkgs, lib, ... }:

{
  services.envfs.enable = false;

  environment.sessionVariables = {
    TRACKER_USE_RUNNER = "0";
    TZ = "Europe/Berlin";
  };

  environment.systemPackages = with pkgs; [
    bind
    appimage-run
    fuse2
    e2fsprogs
    libnotify
    nix-tree
    gcc
    wget
    git
    pciutils
    usbutils
    mesa-demos
    ntfs3g
    unzip
    unrar
    p7zip
    hydra-check
    nvd
    linuxPackages_latest.cpupower
  ];
}
