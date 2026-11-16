{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "ahci" "ehci_pci" "xhci_pci" "usbhid" "uas" "sd_mod" ];
  # "kvm-intel" NICHT fest laden: ohne im BIOS aktives VT-x schlägt der Modulload
  # mit "Operation not supported" fehl (rote Meldung bei jedem Boot). Wird VT-x
  # später aktiviert, lädt der Kernel das Modul per Auto-Alias bei Bedarf selbst.

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
