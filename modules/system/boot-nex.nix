{ config, pkgs, lib, ... }:

{
  imports = [ ./boot-common.nix ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "tcp_bbr" "ntsync" ];

  boot.kernelParams = [
    "preempt=full"
    "split_lock_detect=off"
    "transparent_hugepage=madvise"
    "amd_pstate=active"
    "amdgpu.sg_display=0" 
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
    "vm.swappiness" = 100;
    "kernel.split_lock_mitigate" = 0;
    "kernel.nmi_watchdog" = 0;
  };

  # Nex hat genug RAM für aggressives ZRAM (überschreibt common)
  zramSwap.memoryPercent = lib.mkForce 100;

  # Btrfs Scrub für Gaming-Partition
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" "/gaming" ];
  };

  # Gaming Scheduler
  services.scx = {
    enable = true;
    scheduler = "scx_bpfland";
    extraArgs = [ "-m" "performance" "-P" ];
  };
}
