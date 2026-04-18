{ config, pkgs, lib, ... }:

{
  home-manager.users.mortiferus = { config, ... }: {
    programs.home-manager.enable = true; # [cite: 87]

    #MangoHud Configuration
    programs.mangohud = {
      enable = true;
      # Wir lassen das auf false, damit es nicht global (Desktop/Browser) nervt
      enableSessionWide = false; 
        
	settings = {
        # --- Hardware Filter ---
        pci_dev = "0000:01:00.0";
        
        # --- Layout-Fix ---
        legacy_layout = 1;         # WICHTIG: Auf 1 setzen für manuelle Sortierung
        # table_columns fällt bei legacy_layout=1 weg
        
        font_size = 20;
        background_alpha = "0.4";

        # Die Reihenfolge hier bestimmt jetzt das Overlay:
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

    # mpv Konfiguration [cite: 89]
    programs.mpv = {
      enable = true; # [cite: 89]
      config = {
        vo = "gpu";
        gpu-context = "wayland";
        hwdec = "auto-safe";
        audio-device = "pipewire/GameSink"; # [cite: 90, 91]
        audio-channels = "7.1,5.1,stereo";
        ao = "pipewire";
        osc = "yes";
        border = "no";
        cursor-autohide = 1000;
      }; # [cite: 91]
    };

    # XDG-Links [cite: 92]
    xdg.configFile = {
      "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/niri"; # [cite: 92]
      "noctalia".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/noctalia"; # [cite: 93]
      "pipewire".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/pipewire"; # [cite: 93]
    };

    home.username = "mortiferus"; # [cite: 93]
    home.homeDirectory = "/home/mortiferus";
    home.stateVersion = "25.11";
  };
}
