{ config, pkgs, lib, ... }:

{
  # Gemeinsame Bootloader-Einstellungen
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;

  # Konsolen-Level für sauberen Boot
  boot.consoleLogLevel = 3;

  # Gemeinsame sysctl Netzwerk-Einstellungen
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_fin_timeout" = 5;
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
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    enableNotifications = true;
  };

  # GC
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
