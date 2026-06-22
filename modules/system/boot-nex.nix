{ config, pkgs, lib, smallPkgs, ... }:

# Referenz: /etc/nixos/cachyos-rework-changelog.md
#   Vollständige CachyOS-Vergleichstabelle mit allen übernommenen Features

{
  imports = [ ./boot-common.nix ];

  boot.kernelPackages = smallPkgs.linuxPackages_latest;
  boot.kernelModules = [ "ntsync" ];
  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" "iTCO_wdt" "sp5100_tco" ];

  boot.kernelParams = [
      "transparent_hugepage=madvise"
      "amd_pstate=active"
      "nvidia.NVreg_DynamicPowerManagement=0x02"
    ];


  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
    "vm.swappiness" = 100;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_bytes" = 268435456;
    "vm.dirty_background_bytes" = 67108864;
    "vm.dirty_writeback_centisecs" = 1500;
    "vm.page-cluster" = 0;
    "kernel.nmi_watchdog" = 0;
    "kernel.kptr_restrict" = 2;
    "kernel.printk" = "3 3 3 3";
  };

  # CachyOS-Style: 100% ZRAM, kein Swapfile
  zramSwap.memoryPercent = lib.mkForce 100;

  # CachyOS 30-zram.rules: swappiness=150 + Zswap deaktivieren sobald ZRAM aktiv
  # CachyOS 60-ioschedulers.rules: kyber für NVMe, mq-deadline für SSD, bfq für HDD
  services.udev.extraRules = ''
    ACTION=="change", KERNEL=="zram0", ATTR{initstate}=="1", SYSCTL{vm.swappiness}="150", \
      RUN+="/bin/sh -c 'echo N > /sys/module/zswap/parameters/enabled'"

    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="kyber"
    ACTION=="add|change", KERNEL=="sd*|mmcblk*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

    # CachyOS 99-cpu-dma-latency.rules: audio-Gruppe darf CPU DMA Latenz setzen
    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"

    # CachyOS 20-audio-pm.rules: AC -> snd-hda-intel power_save=0 (kein Crackling)
    ACTION=="add", SUBSYSTEM=="sound", KERNEL=="card*", DRIVERS=="snd_hda_intel", TEST!="/run/udev/snd-hda-intel-powersave", \
      RUN+="/bin/sh -c 'touch /run/udev/snd-hda-intel-powersave; \
        for bat in /sys/class/power_supply/BAT*; do \
          [ \"$$(cat $$bat/status 2>/dev/null)\" != \"Discharging\" ] && { \
            echo $$(cat /sys/module/snd_hda_intel/parameters/power_save) > /run/udev/snd-hda-intel-powersave; \
            echo 0 > /sys/module/snd_hda_intel/parameters/power_save; \
            break; }; done'"

    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="0", TEST=="/sys/module/snd_hda_intel", \
      RUN+="/bin/sh -c 'echo $$(cat /run/udev/snd-hda-intel-powersave 2>/dev/null || echo 1) > /sys/module/snd_hda_intel/parameters/power_save'"

    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="1", TEST=="/sys/module/snd_hda_intel", \
      RUN+="/bin/sh -c '\
        CUR=$$(cat /sys/module/snd_hda_intel/parameters/power_save); \
        [ \"$$CUR\" != 0 ] && echo $$CUR > /run/udev/snd-hda-intel-powersave; \
        echo 0 > /sys/module/snd_hda_intel/parameters/power_save'"

    # CachyOS 40-hpet-permissions.rules: Audio-Gruppe Zugriff auf RTC/HPET (Latenz)
    KERNEL=="rtc0", GROUP="audio"
    KERNEL=="hpet", GROUP="audio"
  '';

  # CachyOS tmpfiles: THP defrag -> defer+madvise (tcmalloc-Optimierung)
  systemd.tmpfiles.rules = [
    "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
    "w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409"
    "e /var/lib/systemd/coredump - - - 3d"
  ];

  # CachyOS systemd system.conf.d: kürzere Timeouts + höhere NOFILE-Limits
  systemd.settings.Manager = {
    DefaultTimeoutStartSec = "15s";
    DefaultTimeoutStopSec = "10s";
    DefaultLimitNOFILE = "2048:2097152";
  };

  # CachyOS systemd user.conf.d: kürzere Timeouts + höhere NOFILE-Limits (User)
  systemd.user.settings.Manager = {
    DefaultTimeoutStartSec = "15s";
    DefaultTimeoutStopSec = "10s";
    DefaultLimitNOFILE = "1024:1048576";
  };

  # CachyOS journald.conf.d: Journal auf 50M begrenzen
  services.journald.extraConfig = ''
    SystemMaxUse=50M
  '';

  # CachyOS 20-audio.conf: @audio Gruppe Echtzeit-Priorität 99
  security.pam.loginLimits = [
    { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
  ];

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

      # CachyOS rtkit-daemon override: Log-Level auf info
      rtkit-daemon.serviceConfig.LogLevelMax = lib.mkDefault "info";

      # CachyOS user@.service delegate: CPU/Cpuset/IO/Memory/PIDs an User-Services
      "user@".serviceConfig.Delegate = "cpu cpuset io memory pids";
    };

}
