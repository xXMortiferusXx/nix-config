{ config, pkgs, lib, smallPkgs, ... }:

{
  imports = [ ./boot-common.nix ];

  boot.kernelPackages = smallPkgs.linuxPackages_latest;
  boot.kernelModules = [ "tcp_bbr" "ntsync" ];
  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" ];

  boot.kernelParams = [
      "split_lock_detect=off"
      "transparent_hugepage=madvise"
      "amd_pstate=active"
      "amdgpu.sg_display=0"
      "usbcore.autosuspend=-1"
      "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    
      # Zwingend nötig für den fehlerfreien VRAM-Standby in NixOS
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1" 
    
      # REAKTIVIERT für Laptops: Erlaubt der Karte in den tiefsten Schlafmodus (RTD3) zu wechseln
      "nvidia.NVreg_DynamicPowerManagement=0x02" 
    ];


  boot.kernel.sysctl = {
    "vm.max_map_count" = 1048576;
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "kernel.split_lock_mitigate" = 0;
  };

  # CachyOS-Style: 100% ZRAM, kein Swapfile
  zramSwap.memoryPercent = lib.mkForce 100;

  # Btrfs Scrub für Gaming-Partition
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" "/gaming" ];
  };

  # Gaming Scheduler
  # HINWEIS: services.scx Modul ist seit NixOS Update kaputt (env list Bug).
  # Workaround: systemd Service manuell definieren.
  # Cake: Automatische Game-Erkennung (Steam/Proton), 4-Klassen, null globale Atomics
  # Falls Cake nicht taugt -> rusty: scx_rusty -o 500 -u 4000 -g 1 -D 90 -K 100 -k -b --perf 1024

  # Manuelle systemd Service + Timer für BTRFS Balance
  systemd.timers = let
    escapeFs = fs: builtins.replaceStrings [ "/" ] [ "-" ] fs;
    balanceTimer = fs: let
      fs' = escapeFs fs;
    in lib.nameValuePair "btrfs-balance-${fs'}" {
      description = "wöchentlicher BTRFS Balance Timer auf ${fs}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        AccuracySec = "1d";
        Persistent = true;
      };
    };
  in lib.listToAttrs (map balanceTimer [ "/" "/gaming" ]);

  systemd.services =
    let
      escapeFs = fs: builtins.replaceStrings [ "/" ] [ "-" ] fs;
      balanceService = fs: let
        fs' = escapeFs fs;
      in lib.nameValuePair "btrfs-balance-${fs'}" {
        description = "BTRFS Balance auf ${fs}";
        after = [ "btrfs-scrub-${fs'}.service" ];
        conflicts = [ "shutdown.target" "sleep.target" ];
        before = [ "shutdown.target" "sleep.target" ];
        serviceConfig = {
          Type = "oneshot";
          Nice = 19;
          IOSchedulingClass = "idle";
          ExecStart = "${pkgs.btrfs-progs}/bin/btrfs balance start -dusage=5 ${fs}";
        };
      };
    in lib.listToAttrs (map balanceService [ "/" "/gaming" ])
    // {
      scx-scheduler = {
        description = "SCX BPFLand Scheduler (Performance)";
        after = [ "systemd-modules-load.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.scx.rustscheds}/bin/scx_bpfland -m performance -P";
          Restart = "on-failure";
          StandardOutput = "journal";
        };
      };
    };

}
