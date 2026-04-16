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
    MANGOHUD_CONFIGFILE = "/home/mortiferus/.config/MangoHud/MangoHud.conf";
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

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  boot.kernelModules = [ "tcp_bbr" "ntsync" ];
  
  services.scx = {
    enable = true;
    scheduler = "scx_rusty";
    extraArgs = [ 
      "-f"           # Force: Ignoriert Warnungen bei der Kern-Zuweisung
      "-u" "2000"    # Slice-Time: 2ms für ruhigere CPU-Last
      "-o" "2000"    # Overload-Interval: Hält Threads stabil auf Kernen
      "-g" "1"       # Greed-Faktor: Wie aggressiv Kerne Aufgaben "klauen"
      "-c" "3"       # Cache-Fokus: Bleibt strikt innerhalb des L3-Caches
      "-k"           # Kill-All: Beendet BPF-Reste sauber beim Stoppen
    ];
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";

  # ────────────── NIX SETTINGS & OPTIMIERUNG ──────────────
  #nix.settings.experimental-features = [ "nix-command" "flakes" ];
  #nix.settings.auto-optimise-store = true;
  # Spart Platz durch Hardlinks

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;

    # Caches für schnelleres Gaming-Setup
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-gaming.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];
   };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
  ];

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
    "net.core.default_qdisc" = "cake"; 
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "fs.file-max" = 2097152;
    "vm.swappiness" = 10;
    "vm.max_map_count" = 2147483647;
    "kernel.sched_itmt_enabled" = 1;
    "net.ipv4.igmp_max_memberships" = 1024;
    "kernel.sched_migration_cost_ns" = 500000;
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
    wget
    git
    htop
    nvtopPackages.full
    pciutils
    usbutils
    mesa-demos
  ];

  # ────────────── NEU: BROWSER POLICIES ──────────────
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
