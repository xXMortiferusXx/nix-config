{ config, pkgs, lib, ... }:

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

  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 60;      # Konservativer auf dem Office-Notebook
    "vm.vfs_cache_pressure" = 100;
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # BTRFS Balance Timer (monatlich, nur Chunks < 5% Auslastung)
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
