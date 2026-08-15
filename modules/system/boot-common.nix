# Gemeinsame Boot-Konfig für alle Hosts
# Importiert cachyos-tuning, setzt systemd-boot, zram, fstrim, chrony, nix.gc
{ config, pkgs, lib, ... }:

{
  imports = [
    ./cachyos-tuning.nix
  ];

  # Gemeinsame Bootloader-Einstellungen
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Konsolen-Level für sauberen Boot
  boot.consoleLogLevel = 3;

  # Gemeinsame sysctl Einstellungen (CachyOS-konform)
  # net.core.netdev_max_backlog bewusst weggelassen — bpftune (cachyos-tuning.nix) steuert das dynamisch
  boot.kernel.sysctl = {
    "fs.file-max" = 2097152;
  };

  # Swap (ZRAM) - 50% CachyOS-Standard für optimales Verhältnis
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = lib.mkDefault 50;
    priority = 100;
  };

  # SSD Wartung
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # NTP Zeit-Sync
  services.chrony = {
    enable = true;
    extraConfig = ''
      server ptbtime1.ptb.de iburst
      server time.cloudflare.com iburst
      pool de.pool.ntp.org iburst
      makestep 1 3
    '';
  };

  # RAM Schutz
  #services.earlyoom = {
  #  enable = true;
  #  freeMemThreshold = 5;
  #  freeSwapThreshold = 20;
  #  enableNotifications = true;
  #};

  # GC
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # /var/lib/nixos für manuelle Updates
  systemd.tmpfiles.settings."nixos" = {
    "/var/lib/nixos" = {
      d = {
        mode = "0755";
        user = "root";
        group = "root";
      };
    };
  };
}
