# CachyOS-inspirierte sysctl/udev/PAM/systemd-Optimierung
# Siehe: https://github.com/CachyOS/linux-cachyos
{ config, pkgs, lib, ... }:

{
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;                 # Bevorzugt Cache vor Swap (SSD vs. RAM-Cache)
    "vm.vfs_cache_pressure" = 50;          # Inodes/Dentrys länger im Cache halten
    "vm.dirty_bytes" = 268435456;          # Max 256MB dirty pages bevor Writeback startet
    "vm.dirty_background_bytes" = 67108864; # Writeback beginnt bei 64MB dirty pages
    "vm.dirty_writeback_centisecs" = 1500;  # Writeback-Daemon läuft alle 15s
    "vm.page-cluster" = 0;                 # Kein Swap-Clustering (SSD, kein Rotationsmedium)
    "kernel.nmi_watchdog" = 0;              # Deaktiviert (spart Strom/CPU-Zyklen)
    "kernel.kptr_restrict" = 2;             # Kernel-Pointer nur für root sichtbar
    "kernel.printk" = "3 3 3 3";           # Nur kritische Meldungen auf Konsole
  };

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

  # CachyOS rtkit-daemon override: Log-Level auf info
  systemd.services.rtkit-daemon.serviceConfig.LogLevelMax = lib.mkDefault "info";

  # CachyOS user@.service delegate: CPU/Cpuset/IO/Memory/PIDs an User-Services
  systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";
}
