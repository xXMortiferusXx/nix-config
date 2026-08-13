{ config, pkgs, lib, ... }:

{
  services.envfs.enable = false;

  environment.sessionVariables = {
    TRACKER_USE_RUNNER = "0";
    TZ = "Europe/Berlin";
    # Qt-Platform-Theme systemweit fuer alle Qt-Apps (qt5ct/qt6ct).
    # Ohne diese Variable zeigen Qt-Apps den Fehler
    # "The QT_QPA_PLATFORMTHEME environment variable is not set".
    QT_QPA_PLATFORMTHEME = "qt6ct";
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
