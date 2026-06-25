{ config, pkgs, lib, ... }:

{
  services.envfs.enable = false;

  environment.sessionVariables.TRACKER_USE_RUNNER = "0";

  environment.systemPackages = with pkgs; [
    bind
    appimage-run
    fuse2
    e2fsprogs
    libnotify
    openldap
    nix-tree
    gcc
    wget
    git
    htop
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
