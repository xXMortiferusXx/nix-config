{ config, pkgs, ... }:

{
  imports = [ ./boot-common.nix ];

  # Stabiler Kernel für Office/Stabilität
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Konservativere Parameter für Intel 6405U (GuC entfernt wegen möglicher Boot-Hänger)
  boot.kernelParams = [
    "intel_pstate=active"
    "i915.enable_fbc=1"        # Framebuffer Compression spart Strom
    "i915.fastboot=1"          # Schnellerer Bootvorgang
  ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 60;      # Konservativer auf dem Office-Notebook
    "vm.vfs_cache_pressure" = 100;
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
}
