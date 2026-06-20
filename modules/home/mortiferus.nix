{ config, pkgs, lib, ... }:

{
  # imports = [ ];
  home-manager.backupFileExtension = "backup";

  home-manager.users.mortiferus = { config, ... }: {
    programs.home-manager.enable = true;

    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      "text/html" = "zen-beta.desktop";
      "text/xml" = "zen-beta.desktop";
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "x-scheme-handler/ftp" = "zen-beta.desktop";
      "x-scheme-handler/about" = "zen-beta.desktop";
      "x-scheme-handler/unknown" = "zen-beta.desktop";
    };

    home.packages = with pkgs; [
      # --- Desktop & Appearance (Theming) ---
      nwg-look               # GTK Konfiguration
      qt6Packages.qt6ct      # Qt6 Konfiguration
      libsForQt5.qt5ct       # Qt5 Konfiguration
      papirus-icon-theme     # Icons
      gnome-themes-extra     # GTK-Kompatibilität (Adwaita)
      shared-mime-info       # Dateizuordnungen

      # --- Wayland & System Utilities ---
      grim                   # Screenshot-Tool
      slurp                  # Bereichsauswahl für Screenshots
      satty                  # Screenshot-Annotation (Modern)
      swappy                 # Screenshot-Editor
      wf-recorder            # Screen-Recording
      wl-clipboard           # Wayland Clipboard
      xsel                   # X11 Clipboard-Bridge
      cliphist               # Clipboard-Historie
      udiskie                # Automount für USB-Sticks
      cacert                 # Zertifikats-Bundle
      xdotool
      xclip

      # --- System Monitoring & Terminal ---
      btop                   # System-Monitor
      #nvtopPackages.full     # GPU-Monitor (Nvidia/AMD/Intel)
      yazi                   # Terminal-Dateimanager

      # --- Apps & Social ---
      nautilus               # Grafischer Dateimanager
      thunar		     # Grafischer Dateimanager
      vesktop                # Discord mit Wayland-Support
      cartridges             # Game-Launcher
      polychromatic          # Razer RGB-Steuerung

      # --- Office & Media ---
      thunderbird-latest     # Mailclient
      libreoffice            # Office-Suite
      hunspellDicts.de_DE    # Deutsche Rechtschreibprüfung
      hyphenDicts.de-de      # Deutsche Silbentrennung
      zathura                # PDF-Viewer (Keyboard-fokussiert)
      loupe                  # Bildbetrachter
      gimp                   # Bildbearbeitung
      naps2                  # Scanner-Software

      # --- Development & 3D Printing ---
      opencode
      #aider-chat             # KI-Pair-Programming
      #helix                  # Modal-Editor
      prusa-slicer           # 3D-Druck Slicer
      orca-slicer            # 3D-Druck Slicer

      # --- Python-Umgebung (poe-price-checker) ---
      (python3.withPackages (ps: with ps; [
        pyqt6
        httpx
        pyperclip
        pynput
      ]))
    
    ];

    home.file.".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";
    
    xdg.configFile = {

      "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/niri";
      "noctalia".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/noctalia";
      "pipewire".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/pipewire";
      "nvim".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/nvim";
      "hypr".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/hypr";

    };
    
    programs.mangohud = {
      enable = true;
      enableSessionWide = false;
      settings = {
        pci_dev = "0000:01:00.0";
        legacy_layout = 1;
        font_size = 20;
        background_alpha = "0.4";
        cpu_stats = true;
        cpu_temp = true;
        cpu_mhz = true;
        cpu_color = "2E97CB";
        gpu_stats = true;
        gpu_temp = true;
        gpu_core_clock = true;
        vram = true;
        gpu_color = "2E9762";
        ram = true;
        fps = true;
        fps_metrics = "avg+0.01";
        frame_timing = true;
      };
    };
    
    # mpv
    programs.mpv = {
      enable = true;
      config = {
        vo = "gpu";
        gpu-context = "wayland";
        hwdec = "auto-safe";
        audio-device = "pipewire/GameSink";
        audio-channels = "7.1,5.1,stereo";
        ao = "pipewire";
        osc = "yes";
        border = "no";
        cursor-autohide = 1000;
      };
    };

    home.username = "mortiferus";
    home.homeDirectory = "/home/mortiferus";
    home.stateVersion = "26.05";
  };
}
