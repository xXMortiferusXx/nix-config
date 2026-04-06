{ config, pkgs, ... }:

{
  networking.hostName = "Mortiferus-PC";
  networking.networkmanager.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Systemweite Umgebungsvariablen
  environment.variables = {
    # Nvidia Shader Cache auf ca. 12GB festlegen (CachyOS Optimierung)
    "__GL_SHADER_DISK_CACHE_SIZE" = "12000000000";
  };
  
  # Ermöglicht Standardpfade wie /bin/bash für deine alten Scripte
  services.envfs.enable = true;

  # Verhindert den "/usr/bin" Mount-Fehler (erzeugt Symlink für Kompatibilität)
  systemd.tmpfiles.rules = [
    "L+ /usr/bin - - - - /bin"
  ];

  # ────────────── Kernel & Hardware-Tweaks ──────────────
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernelParams = [ 
    "nvidia.NVreg_RegistryDwords=PowerMizerEnable=0x1;PerfLevelSrc=0x3322;PowerMizerDefaultAC=0x1" 
    "nvidia.NVreg_EnableResizableBar=1"
  ];

  # ────────────── NVIDIA & Dynamic Boost ──────────────
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    dynamicBoost.enable = true; 
    package = config.boot.kernelPackages.nvidia_x11;
  };

  # ────────────── Scheduler (SCX) ──────────────
  services.scx = {
    enable = true;
    scheduler = "scx_cake";
    extraArgs = [ "--profile" "gaming" ];
  };

  # ────────────── Bootloader ──────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ────────────── Sudo & Berechtigungen ──────────────
  security.sudo.extraRules = [{
    users = [ "mortiferus" ];
    commands = [{
      command = "/run/current-system/sw/bin/nvidia-smi";
      options = [ "NOPASSWD" ];
    }];
  }];

  # Korrigierte Udev-Regeln
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
    ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="nvme[0-9]*n[0-9]", ATTR{queue/scheduler}="kyber"
    SUBSYSTEM=="platform", RUN+="${pkgs.coreutils}/bin/chmod -R 666 /sys/firmware/acpi/platform_profile"
  '';

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "cake"; 
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "fs.file-max" = 2097152;
    "vm.swappiness" = 10;
    "vm.max_map_count" = 2147483647;
    "kernel.sched_itmt_enabled" = 1;
  };

  # ────────────── Optimierungen & Software ──────────────
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100; 
    priority = 100;
  };

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  environment.systemPackages = with pkgs; [
    wget git fastfetch htop nvtopPackages.full pciutils usbutils mesa-demos lenovo-legion
    config.services.scx.package
  ];
}
