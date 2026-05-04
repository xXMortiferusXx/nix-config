{ config, pkgs, ... }:

{
  networking.hostName = "Mortiferus-PC";
  networking.networkmanager.enable = true;
  nixpkgs.config.allowUnfree = true;

  environment.variables = {
    "__GL_SHADER_DISK_CACHE_SIZE" = "12000000000";
    "VDPAU_DRIVER" = "va_gl";
  };

  services.envfs.enable = false;
  networking.firewall.enable = true;

  # ────────────────── KERNEL & PERFORMANCE ──────────────────
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelModules = [ 
    "tcp_bbr" 
    "ntsync" 
    "zenergy"
  ];
  # Level 3 zeigt nur Fehler & Warnungen an. Unterdrückt normales Rauschen,
  # lässt aber kritische Boot-Meldungen sichtbar, falls etwas schiefgeht.
  boot.consoleLogLevel = 3;

  hardware.openrazer.enable = true;


services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ 
       "--autopower"
#      "-f"
#      "-u" "2000"
#      "-o" "2000"
#      "-g" "1"
#      "-c" "3"
#      "-k"
    ];
  };


  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";

  # ────────────────── CONSOLE / TTY ──────────────────
  # Stellt sicher, dass Umlaute im TTY korrekt dargestellt werden und das
  # deutsche Tastaturlayout auch ohne grafische Oberfläche funktioniert.
  # useXkbConfig muss false sein, da es sonst mit der manuellen keyMap kollidiert
  # und eine Ableitung (derivation) erwartet, was den Build-Fehler verursacht.
  console = {
    keyMap = "de-latin1";
    useXkbConfig = false;
  };

  # ────────────────── NIX SETTINGS ──────────────────
  nix.settings = {
    experimental-features = [ 
      "nix-command" 
      "flakes" 
    ];
    auto-optimise-store = true;
    substituters = [ 
      "https://cache.nixos.org/" 
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
    # Nur steam-run hat eine garantierte multiPkgs-Schnittstelle
    ++ (pkgs.steam-run.args.multiPkgs pkgs);
  };

  # ────────────── HARDWARE & OPTIMIERUNG ──────────────
  hardware.cpu.amd.updateMicrocode = true;
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  security.sudo.extraRules = [
    {
      users = [ "mortiferus" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nvidia-smi";
          options = [ "NOPASSWD" ];
        }
        # Erlaubt passwordloses tee auf CPU-Energieprofil (für game-performance Skript)
        {
          command = "/run/current-system/sw/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="kyber"
  '';

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "vm.max_map_count" = 2147483642;
    "vm.mmap_min_addr" = 0; # SheepShaver
    "fs.file-max" = 2097152;
    "kernel.split_lock_mitigate" = 0;
    "net.core.netdev_max_backlog" = 4096;
    "net.ipv4.tcp_fin_timeout" = 5;
    "vm.dirty_background_bytes" = 67108864;
    "vm.dirty_bytes" = 268435456;
    "vm.dirty_writeback_centisecs" = 1500;
    "vm.vfs_cache_pressure" = 50;
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
    enable = false;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
  };

  environment.systemPackages = with pkgs; [
    libnotify
    openldap
    nix-tree
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
        "zen.window-sync.enabled" = {
        Value = false;
        Status = "locked";
        };
      };
    };
  };
}
