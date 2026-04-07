{ config, pkgs, ... }:

{
  networking.hostName = "Mortiferus-PC";
  networking.networkmanager.enable = true;
  nixpkgs.config.allowUnfree = true;

  environment.variables = {
    "__GL_SHADER_DISK_CACHE_SIZE" = "12000000000";
    "XCURSOR_THEME" = "Bibata-Modern-Classic";
    "XCURSOR_SIZE" = "24";
    "VDPAU_DRIVER" = "va_gl";
    "LIBVA_DRIVER_NAME" = "radeonsi"; # Erzwingt Video-Dekodierung auf AMD
  };
  
  # ────────────── DER SAUBERE WEG FÜR SCRIPTE ──────────────
  # Wir schalten envfs AUS, um den Boot-Fehler zu killen.
  services.envfs.enable = false;

  # Stattdessen verlinken wir NUR die bash dorthin, wo Scripte sie suchen.
  # Das erzeugt keinen Mount-Konflikt!
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
    "L+ /usr/bin/env - - - - ${pkgs.coreutils}/bin/env"
  ];
  # ─────────────────────────────────────────────────────────

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernelParams = [ 
    "nvidia.NVreg_RegistryDwords=PowerMizerEnable=0x1;PerfLevelSrc=0x3322;PowerMizerDefaultAC=0x1" 
    "nvidia.NVreg_EnableResizableBar=1"
    "split_lock_detect=off"
    "transparent_hugepage=madvise"
    "amd_pstate=active"
    "amdgpu.sg_display=0" # Hilft bei manchen AMD/Nvidia-Laptops gegen leichtes Stottern im Bild
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    dynamicBoost.enable = true; 
    package = config.boot.kernelPackages.nvidia_x11;
  };

  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ "--performance"];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";
  
  # ────────────── NIX SETTINGS & OPTIMIERUNG ──────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true; # Spart Platz durch Hardlinks

  # ────────────── HARDWARE FEINSCHLIFF ──────────────
  hardware.cpu.amd.updateMicrocode = true; # Wichtig für AMD Stabilität
  services.fstrim = {
    enable = true;
    interval = "weekly"; # Das ist der Standard, kannst du auch weglassen
  };
  # ────────────────────────────────────────────────────────




  security.sudo.extraRules = [{
    users = [ "mortiferus" ];
    commands = [{
      command = "/run/current-system/sw/bin/nvidia-smi";
      options = [ "NOPASSWD" ];
    }];
  }];

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
    ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="nvme[0-9]*n[0-9]", ATTR{queue/scheduler}="kyber"
    SUBSYSTEM=="platform", RUN+="${pkgs.coreutils}/bin/chmod -R 666 /sys/firmware/acpi/platform_profile"
  '';

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq_codel"; 
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "fs.file-max" = 2097152;
    "vm.swappiness" = 10;
    "vm.max_map_count" = 2147483647;
    "kernel.sched_itmt_enabled" = 1;
    "net.ipv4.igmp_max_memberships" = 1024;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100; 
    priority = 100;
  };

  #services.ananicy = {
  #  enable = true;
  #  package = pkgs.ananicy-cpp;
  #  rulesProvider = pkgs.ananicy-rules-cachyos;
  #};

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
