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

  services.envfs.enable = true;
  networking.firewall.enable = true;
  # Check hydra for the build status of a package.
  # e.g. `hydra-check --channel unstable galculator`.
  
  # ────────────────── KERNEL & PERFORMANCE ──────────────────
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ 
    "tcp_bbr" 
    "ntsync" 
  ];

  services.scx = {
    enable = true;
    scheduler = "scx_rusty";
    extraArgs = [ 
      "-f"           # Force
      "-u" "2000"    # Slice-Time
      "-o" "2000"    # Overload-Interval
      "-g" "1"       # Greed-Faktor
      "-c" "3"       # Cache-Fokus
      "-k"           # Kill-All
    ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";

  # ────────────────── NIX SETTINGS ──────────────────
  nix.settings = {
    experimental-features = [ 
      "nix-command" 
      "flakes" 
    ];
    auto-optimise-store = true;
    substituters = [ 
      "https://cache.nixos.org/" 
      "https://nix-gaming.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];
  };

  # ────────────────── NIX-LD & GAMING LIBS ──────────────────
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # --- System & Core ---
      stdenv.cc.cc
      zlib
      fuse3
      icu
      nss
      openssl
      curl
      expat
      glib
      dbus
      libuuid
      libusb1
      libnghttp2
      libidn2
      libssh2
      libssh
      openldap
      libpsl
      libkrb5
      keyutils
      p11-kit
      libtasn1
      
      # --- Grafik, Fonts & UI ---
      libGL
      libGLU
      mesa
      freetype
      fontconfig
      pango
      cairo
      atk
      gdk-pixbuf
      gtk3
      alsa-lib
      at-spi2-core

      # --- X11 & XCB ---
      libx11
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrender
      libxtst
      libxcomposite
      libxrandr
      libxinerama
      libsm
      libice
      libxcb
      libxshmfence
      libxkbcommon
      libxmu
      libxft
      xcbutil
      xcbutilwm
      xcbutilimage
      xcbutilkeysyms
      xcbutilrenderutil
      xcbutilcursor

      # --- Kompression & Math ---
      gmp
      libmpc
      mpfr
      lz4
      zstd
      bzip2
      libgcrypt
      libgpg-error
      libxml2
      sqlite
      libunwind
      libelf
      e2fsprogs
      libxcrypt-legacy

      # --- Media & Ergänzungen ---
      libtool
      libao
      libidn
      libunistring
      libedit
      libvdpau
      libva
      libdrm
      freeglut
      libtheora
      libogg
      libvorbis
      libvpx
      wayland
      gtk2
      util-linux
    ] 
    ++ (pkgs.steam-run.args.multiPkgs pkgs)
    ++ (pkgs.heroic.args.multiPkgs pkgs)
    ++ (pkgs.lutris.args.multiPkgs pkgs);
  };

  # ────────────── HARDWARE & OPTIMIERUNG ──────────────
  hardware.cpu.amd.updateMicrocode = true;
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  security.sudo.extraRules = [{
    users = [ "mortiferus" ];
    commands = [{
      command = "/run/current-system/sw/bin/nvidia-smi";
      options = [ "NOPASSWD" ];
    }];
  }];

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
    SUBSYSTEM=="platform", RUN+="${pkgs.coreutils}/bin/chmod -R 666 /sys/firmware/acpi/platform_profile"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="kyber"
  '';

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "fs.file-max" = 2097152;
    "vm.swappiness" = 10;
    "vm.max_map_count" = 2147483642;
    #"kernel.sched_itmt_enabled" = 1;        #Für Intel CPU's
    "net.ipv4.igmp_max_memberships" = 1024;
    "kernel.sched_migration_cost_ns" = 500000;
    "kernel.sched_cfs_bandwidth_slice_u" = 3000;
    "kernel.sched_latency_ns" = 3000000;
    "kernel.sched_min_granularity_ns" = 300000;
    "kernel.sched_wakeup_granularity_ns" = 500000;
    "kernel.sched_nr_migrate" = 32;
    "kernel.split_lock_mitigate" = 0;
    "net.ipv4.tcp_mtu_probing" = true;
    "net.ipv4.tcp_fin_timeout" = 5;
    "kernel.sched_rt_runtime_us" = -1;
    "vm.dirty_ratio" = 10;            #Optional
    "vm.dirty_background_ratio" = 5;  #Optional
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    priority = 100;
  };
  

  services.btrfs.autoScrub = {
  enable = true;
  interval = "monthly";
  fileSystems = [ 
    "/" 
    "/gaming" 
   ]; 
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
  };

  environment.systemPackages = with pkgs; [
    gcc
    wget
    git
    htop
    nvtopPackages.full
    pciutils
    usbutils 
    mesa-demos
    ntfs3g
    unzip
    unrar
    p7zip
    hydra-check
    nvd
  ];

  # ────────────── BROWSER POLICIES ──────────────
  environment.etc."zen/policies/policies.json".text = builtins.toJSON {
    policies = {
      Preferences = {
        "ui.context_menus.after_remote_menus" = {
          Value = true;
          Status = "locked";
        };
        "privacy.resistFingerprinting.letterboxing" = {
          Value = false;
          Status = "locked";
        };
      };
    };
  };

  system.stateVersion = "25.11";
}
