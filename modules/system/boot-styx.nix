{ config, pkgs, lib, ... }:

{
  imports = [ ./boot-common.nix ];

  # Referenz: /etc/nixos/cachyos-rework-changelog.md

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    "intel_pstate=active"
    "i915.enable_fbc=1"
    "i915.fastboot=1"
  ];

  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" "iTCO_wdt" ];

  boot.kernel.sysctl = {
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

  services.udev.extraRules = ''
    ACTION=="change", KERNEL=="zram0", ATTR{initstate}=="1", SYSCTL{vm.swappiness}="150", \
      RUN+="/bin/sh -c 'echo N > /sys/module/zswap/parameters/enabled'"

    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="kyber"
    ACTION=="add|change", KERNEL=="sd*|mmcblk*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"

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

    KERNEL=="rtc0", GROUP="audio"
    KERNEL=="hpet", GROUP="audio"
  '';

  systemd.tmpfiles.rules = [
    "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
    "w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409"
    "e /var/lib/systemd/coredump - - - 3d"
  ];

  systemd.settings.Manager = {
    DefaultTimeoutStartSec = "15s";
    DefaultTimeoutStopSec = "10s";
    DefaultLimitNOFILE = "2048:2097152";
  };

  systemd.user.settings.Manager = {
    DefaultTimeoutStartSec = "15s";
    DefaultTimeoutStopSec = "10s";
    DefaultLimitNOFILE = "1024:1048576";
  };

  services.journald.extraConfig = ''
    SystemMaxUse=50M
  '';

  systemd.services.rtkit-daemon.serviceConfig.LogLevelMax = lib.mkDefault "info";
  systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";

  security.pam.loginLimits = [
    { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
  ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  systemd.timers."btrfs-balance--" = {
    description = "wöchentlicher BTRFS Balance Timer auf /";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      AccuracySec = "1d";
      Persistent = true;
    };
  };

  systemd.services."btrfs-balance--" = {
    description = "BTRFS Balance auf /";
    after = [ "btrfs-scrub--.service" ];
    conflicts = [ "shutdown.target" "sleep.target" ];
    before = [ "shutdown.target" "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      Nice = 19;
      IOSchedulingClass = "idle";
      ExecStart = "${pkgs.btrfs-progs}/bin/btrfs balance start -dusage=5 /";
    };
  };
}
