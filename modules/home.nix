{ config, pkgs, lib, ... }:

{
  home-manager.users.mortiferus = { config, ... }: {

    programs.home-manager.enable = true;

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
