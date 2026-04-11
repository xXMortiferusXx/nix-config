{ config, pkgs, lib, ... }:

{
  home-manager.users.mortiferus = { config, ... }: {

    programs.home-manager.enable = true;

    programs.mangohud = {
      enable = true;
      enableSessionWide = true; 
      
      package = (pkgs.mangohud.overrideAttrs (oldAttrs: {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
        postInstall = (oldAttrs.postInstall or "") + ''
          wrapProgram $out/bin/mangohud \
            --prefix LD_LIBRARY_PATH : "/run/opengl-driver/lib:/run/opengl-driver-32/lib"
        '';
      }));

      settings = {
        # --- Layout & Basis ---
        legacy_layout = 0;
        horizontal = false;
        table_columns = 3;
        font_size = 20;
        background_alpha = "0.2";
        background_color = "000000";
        position = "top-left";
        text_color = "FFFFFF";
        round_corners = 0;

        # --- GPU (Nur NVIDIA GPU0) ---
        gpu_list = "0";
        gpu_stats = true;
        gpu_text = "NVIDIA";
        gpu_color = "2E9762";
        gpu_load_change = true;
        gpu_core_clock = true;
        gpu_mem_clock = true;
        gpu_temp = true;
        gpu_power = true;
        vram = true;
        vram_color = "AD64C1";

        # --- CPU ---
        cpu_stats = true;
        cpu_text = "CPU";
        cpu_color = "2E97CB";
        cpu_load_change = true;
        cpu_mhz = true;
        cpu_temp = true;
        cpu_power = true;

        # --- RAM ---
        ram = true;
        ram_color = "C26693";

        # --- FPS & Performance ---
        fps = true;
        fps_metrics = "avg,0.01"; # Aktiviert AVG und 1% Lows
        fps_color_change = true;
        fps_value = "30,60";
        fps_color = "B22222,FDFD09,39F900";

        # Frametime Graph
        frame_timing = true;
        frametime_color = "00FF00";
        show_fps_limit = false; # FPS Limit Anzeige entfernt

        # --- System & Blacklist ---
        vsync = 4;
        output_folder = "/home/mortiferus/.local/share/goverlay";
        blacklist = "zenity,protonplus,lsfg-vk-ui,bazzar,gnome-calculator,pamac-manager,lact,ghb,bitwig-studio,ptyxis,yumex";
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

    # XDG-Links
    xdg.configFile = {
      "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/niri";
      "noctalia".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/noctalia";
      "pipewire".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/pipewire";
    };

    home.username = "mortiferus";
    home.homeDirectory = "/home/mortiferus";
    home.stateVersion = "25.11";
  };
}
