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
    "LIBVA_DRIVER_NAME" = "radeonsi";
    "WLR_RENDERER" = "vulkan";
  };

  services.envfs.enable = false;
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
    "L+ /usr/bin/env - - - - ${pkgs.coreutils}/bin/env"
    "w /sys/devices/system/cpu/amd_pstate/status - - - - active"
    "w /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference - - - - performance"
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernelParams = [ 
    "split_lock_detect=off"
    "transparent_hugepage=madvise"
    "amd_pstate=active"
    "amd_iommu=on"
    "amdgpu.sg_display=0"
    "nvidia.NVreg_RegistryDwords=PowerMizerEnable=0x1;PowerMizerDefaultAC=0x1"
    "nvidia.NVreg_EnableResizableBar=1"
  ];

  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ "--performance"];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZRAM (Wichtig für Performance)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100; 
    priority = 100;
  };

  # Der vermisste Editor
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    substituters = [ "https://cache.nixos.org/" "https://nix-gaming.cachix.org" ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc zlib fuse3 icu nss openssl curl expat
    libxkbcommon wayland mesa libGL 
  ];

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "vm.max_map_count" = 2147483647;
    "fs.file-max" = 2097152;
    "vm.swappiness" = 10;
    "kernel.sched_migration_cost_ns" = 500000;
  };

  environment.systemPackages = with pkgs; [
    wget git htop pciutils usbutils mangohud nvtopPackages.full
  ];
}
