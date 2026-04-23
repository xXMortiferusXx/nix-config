{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "uas" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];

  # Gaming-Platte via Label
  fileSystems."/gaming" = {
    device = "/dev/disk/by-label/GamingDrive";
    fsType = "btrfs";
    options = [ 
      "defaults"
      "noatime"
      "nodiratime"
      "compress=zstd"
      "commit=60"
      "nofail" 
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
