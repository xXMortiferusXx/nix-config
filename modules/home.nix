{ config, pkgs, lib, ... }:

{
  home-manager.users.mortiferus = { config, ... }: {
    programs.home-manager.enable = true;

    # Erzwungene Installation des Icon-Pakets
    home.packages = [
      pkgs.papirus-icon-theme
    ];

    # Symlink-Brechstange für widerspenstige GTK4 Apps
    home.file.".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";

    # Einstellung für Themes und Icons (Dconf für GNOME/GTK4)
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        icon-theme = "Papirus";
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk3"; 
      style.name = "adwaita"; 
    };

    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus"; # Eventuell "Papirus-Dark" probieren, falls "Papirus" nicht greift
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
      };
      
      gtk2.extraConfig = "gtk-icon-theme-name=\"Papirus\"";
      gtk3.extraConfig = {
        gtk-icon-theme-name = "Papirus";
      };
      gtk4.extraConfig = {
        gtk-icon-theme-name = "Papirus";
      };

      gtk4.theme = null; 
    };

    # Zusammengeführte XDG-Konfigurationen
    xdg.configFile = {
      "qt5ct/qt5ct.conf".text = ''
        [Appearance]
        icon_theme=Papirus
        cursor_theme=Bibata-Modern-Classic
        custom_palette=false
        style=fusion
      '';
      "qt6ct/qt6ct.conf".text = ''
        [Appearance]
        icon_theme=Papirus
        cursor_theme=Bibata-Modern-Classic
        custom_palette=false
        style=fusion
      '';
      "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/niri";
      "noctalia".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/noctalia";
      "pipewire".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/pipewire";
    };

    # MangoHud Configuration
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

    # mpv Konfiguration
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
