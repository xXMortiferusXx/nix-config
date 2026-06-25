{ config, pkgs, lib, ... }:

let
  cfg = config.my.btrfs;
  escapeFs = fs: builtins.replaceStrings [ "/" ] [ "-" ] fs;
in {
  options.my.btrfs.fileSystems = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ "/" ];
    description = "Filesystems for btrfs scrub and balance";
  };

  config = {
    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = cfg.fileSystems;
    };

    systemd.timers = builtins.listToAttrs (map (fs: let
      fs' = escapeFs fs;
    in lib.nameValuePair "btrfs-balance-${fs'}" {
      description = "wöchentlicher BTRFS Balance Timer auf ${fs}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        AccuracySec = "1d";
        Persistent = true;
      };
    }) cfg.fileSystems);

    systemd.services = builtins.listToAttrs (map (fs: let
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
    }) cfg.fileSystems);
  };
}
