  # CachyOS-inspirierte sysctl/udev/PAM/systemd-Optimierung
  # Siehe: https://github.com/CachyOS/linux-cachyos
  { config, pkgs, lib, ... }:

  {
    options.tuning.ioScheduler = lib.mkOption {
      type = lib.types.str;
      default = "kyber";
      example = "adios";
      description = ''
        I/O-Scheduler, den die udev-Regeln fuer SSD/NVMe setzen.
        "adios" nur setzen, wenn der laufende Kernel es mitbringt
        (CachyOS-Kernel). Auf anderen Kerneln (z. B. linuxPackages_zen auf
        styx) existiert es nicht, die Regel laeuft dann still ins Leere und der
        Kernel nimmt seinen Default. CachyOS-Hosts setzen in boot-<host>.nix
        auf "adios"; hier bleibt es der Default fuer Nicht-CachyOS-Kernels.
      '';
    };


    # Option deklariert -> Attribute müssen unter config stehen.
  config = {
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
      "kernel.unprivileged_userns_clone" = 1; # Unprivileged User-Namespaces für Flatpak/Container

      # BBR + fq (default_qdisc greift bei wlan0 wegen IFF_NO_QUEUE nicht).
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fin_timeout" = 5;
      "net.core.rmem_max" = 2500000;
    };

    # BBR-Modul sicher beim Boot laden (sonst greift die sysctl erst beim Modulload)
    boot.kernelModules = [ "tcp_bbr" ];

    services.udev.extraRules = ''
      ACTION=="change", KERNEL=="zram0", ATTR{initstate}=="1", SYSCTL{vm.swappiness}="150", \
        RUN+="/bin/sh -c 'echo N > /sys/module/zswap/parameters/enabled'"

      # Scheduler nur auf ganze Block-Devices (DEVTYPE=disk) setzen —
      # Partitionen (nvme0n1p1, sda1, ...) haben kein queue/scheduler-Attribut
      # und erzeugen sonst udev-"Could not chase"-Fehler
      #
      # Scheduler-Wert kommt aus ioScheduler (Default "kyber"). CachyOS-Hosts
      # uebersteuern auf "adios" (nur dort vorhanden) — siehe boot-<host>.nix.
      ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="nvme[0-9]*n[0-9]*", ENV{DEVTYPE}=="disk", ATTR{queue/scheduler}="${config.tuning.ioScheduler}"
      ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd*|mmcblk*", ENV{DEVTYPE}=="disk", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="${config.tuning.ioScheduler}"
      ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd*", ENV{DEVTYPE}=="disk", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

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

    # THP defrag -> defer+madvise (tcmalloc-Optimierung)
    systemd.tmpfiles.rules = [
      "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
      "w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409"
      "e /var/lib/systemd/coredump - - - 3d"
    ];

    # Coredumps AUS: NICHT systemd.coredump.enable=false (schreibt core.* ins Home) -> Soft-Limits auf 0.
    systemd.coredump.enable = true;
    systemd.settings.Manager.DefaultLimitCORESoft = "0";
    systemd.user.settings.Manager.DefaultLimitCORESoft = "0";

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

    # bpftune: dynamische Netzwerk-Optimierung via BPF.
    services.bpftune.enable = true;

    services.journald.settings.Journal.SystemMaxUse = "50M";

    services.locate = {
      enable = true;
      interval = "hourly";
      package = pkgs.plocate;
    };

    security.pam.loginLimits = [
      { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
    ];

    systemd.services.rtkit-daemon.serviceConfig.LogLevelMax = lib.mkDefault "info";

    systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";
  };
}
