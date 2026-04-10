{ config, pkgs, lib, ... }:

{
  home-manager.users.mortiferus = { config, ... }: {

    programs.home-manager.enable = true;
    
    programs.mpv = {
        enable = true;
        config = {
    # Video-Backend für Niri/Wayland
        vo = "gpu";
        gpu-context = "wayland";
        hwdec = "auto-safe";

    # Audio-Konfiguration
        audio-device = "pipewire/GameSink"; # Erzwingt die Ausgabe auf dein GameSink Device
        audio-channels = "7.1,5.1,stereo";  # Bevorzugt 8-Kanal (7.1), falls vorhanden
        ao = "pipewire";                    # Nutzt direkt das Pipewire-Backend
    
    # GUI & Komfort
        osc = "yes";
        border = "no";
        cursor-autohide = 1000;
     };
   };


    # XDG-Config-Links (Live-Editierbar & Git-Safe)
    xdg.configFile = {
      # Fenster-Manager
      "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/niri";
      
      # Design-System
      "noctalia".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/noctalia";
      
      # Gaming-Overlay
      "MangoHud".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/MangoHud";

      # Audio-Routing & Mixer (für deine chatmixer.conf)
      "pipewire".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/pipewire";
    };

    home.username = "mortiferus";
    home.homeDirectory = "/home/mortiferus";
    home.stateVersion = "25.11";
  };
}
