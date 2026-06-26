{ config, pkgs, lib, ... }:

{
  imports = [ ./boot-common.nix ];

  my.btrfs.fileSystems = [ "/" "/gaming" ];

  #boot.kernelPackages = smallPkgs.linuxPackages_latest; # alt (nixpkgs-small)
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3;
  boot.kernelModules = [ "ntsync" ];
  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" "iTCO_wdt" "sp5100_tco" ];

  boot.kernelParams = [
    "transparent_hugepage=madvise"
    "amd_pstate=active"
    "nvidia.NVreg_DynamicPowerManagement=0x02"
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
  };

  zramSwap.memoryPercent = lib.mkForce 100;

  #systemd.services.scx-scheduler = { # kein scx unter BORE
  #  description = "SCX BPFLand Scheduler (Performance)";
  #  after = [ "systemd-modules-load.service" ];
  #  wantedBy = [ "multi-user.target" ];
  #  serviceConfig = {
  #    Type = "simple";
  #    ExecStart = "${pkgs.scx.rustscheds}/bin/scx_bpfland -m performance -P";
  #    Restart = "on-failure";
  #    StandardOutput = "journal";
  #  };
  #};
}
