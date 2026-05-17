{ config, pkgs, lib, ... }:

{
  imports = [ ];
  home-manager.backupFileExtension = "backup";

  home-manager.users.mortiferus = { config, ... }: {
    programs.home-manager.enable = true;

    home.packages = with pkgs; [
      # Sidekick Nativ Starter - Clean Version
      (pkgs.writeShellScriptBin "sidekick-nativ" ''
        TARGET_DIR="$HOME/Apps/Sidekick-extracted"
        APPIMAGE="$HOME/Apps/Sidekick-linux-stable.AppImage"
        DOTNET_COMBINED="$HOME/.dotnet_sidekick"

        if [ ! -d "$TARGET_DIR" ]; then
          mkdir -p "$TARGET_DIR"
          cd "$HOME/Apps"
          chmod +x "$APPIMAGE"
          "$APPIMAGE" --appimage-extract > /dev/null
          mv squashfs-root/* "$TARGET_DIR/"
          rm -rf squashfs-root
        fi

        rm -rf "$DOTNET_COMBINED"
        mkdir -p "$DOTNET_COMBINED"
        REAL_DOTNET="${pkgs.dotnet-runtime_8}"
        ln -s "$REAL_DOTNET/share/dotnet/shared" "$DOTNET_COMBINED/shared"
        mkdir -p "$DOTNET_COMBINED/host"
        ln -s "$REAL_DOTNET/share/dotnet/host/fxr" "$DOTNET_COMBINED/host/fxr"

        export DOTNET_ROOT="$DOTNET_COMBINED"
        FXR_VER=$(ls "$DOTNET_COMBINED/host/fxr" | head -n 1)
        
        # --- MINIMAL-KONFIGURATION ---
        export GDK_BACKEND=x11
        
        # WebKit Stabilität (Sandbox-Fix für neuere WebKit-Versionen)
        export WEBKIT_DISABLE_COMPOSITING_MODE=1
        export WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1
        
        # Netzwerk & SSL (unverzichtbar für Bilder/Preise)
        export GIO_EXTRA_MODULES="${pkgs.glib-networking}/lib/gio/modules"
        export SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"
        export NIX_SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"
        
        # Pfade
        export GST_PLUGIN_SYSTEM_PATH_1_0="${lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
          pkgs.gst_all_1.gstreamer
          pkgs.gst_all_1.gst-plugins-base
          pkgs.gst_all_1.gst-plugins-good
        ]}"
        export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS"
        
        export LD_LIBRARY_PATH="${lib.makeLibraryPath [
          dotnet-runtime_8
          webkitgtk_4_1
          gtk3
          glib
          zlib
          icu
          openssl
          nss
          nspr
          atk
          at-spi2-atk
          cups
          libdrm
          mesa
          libxkbcommon
          pango
          cairo
          libX11
          libXcomposite
          libXdamage
          libXext
          libXfixes
          libXi
          libXrandr
          libXrender
          libXtst
          libnotify
          libsecret
          libappindicator-gtk3
          gdk-pixbuf
          librsvg
          libsoup_3
          fontconfig
          freetype
          harfbuzz
          libglvnd
          glib-networking
          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
          libva
          libinput
          xsel
          stdenv.cc.cc.lib
        ]}:$DOTNET_COMBINED/host/fxr/$FXR_VER"

        exec "$TARGET_DIR/usr/bin/Sidekick" "$@"
      '')

      # --- Desktop & Appearance (Theming) ---
      nwg-look               # GTK Konfiguration
      qt6Packages.qt6ct      # Qt6 Konfiguration
      libsForQt5.qt5ct       # Qt5 Konfiguration
      papirus-icon-theme     # Icons
      bibata-cursors         # Mauszeiger
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
      kitty                  # Standard Terminal
      btop                   # System-Monitor
      nvtopPackages.full     # GPU-Monitor (Nvidia/AMD/Intel)
      yazi                   # Terminal-Dateimanager
      jq                     # JSON-Prozessor

      # --- Apps & Social ---
      nautilus               # Grafischer Dateimanager
      thunar		     # Grafischer Dateimanager
      vesktop                # Discord mit Wayland-Support
      legcord                # Alternativer Discord-Client
      cartridges             # Game-Launcher
      polychromatic          # Razer RGB-Steuerung

      # --- Office & Media ---
      libreoffice            # Office-Suite
      hunspellDicts.de_DE    # Deutsche Rechtschreibprüfung
      hyphenDicts.de-de      # Deutsche Silbentrennung
      zathura                # PDF-Viewer (Keyboard-fokussiert)
      loupe                  # Bildbetrachter
      gimp                   # Bildbearbeitung
      naps2                  # Scanner-Software

      # --- Development & 3D Printing ---
      aider-chat             # KI-Pair-Programming
      helix                  # Modal-Editor
      prusa-slicer           # 3D-Druck Slicer
      orca-slicer            # 3D-Druck Slicer
    
    ];

    # Desktop-Entries & Theme-Config (unverändert)
    xdg.desktopEntries.sidekick = {
      name = "Sidekick";
      exec = "sidekick-nativ"; 
      icon = "/home/mortiferus/Apps/sidekick-linux.png";
      terminal = false;
      categories = [ "Game" ];
    };

    home.file.".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";
    
    xdg.configFile = {

      "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/niri";
      "noctalia".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/noctalia";
      "pipewire".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/pipewire";
      "nvim".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/nvim";
      "hypr".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/hypr";
      "kitty".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/kitty";
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
    home.stateVersion = "25.11";
  };
}
