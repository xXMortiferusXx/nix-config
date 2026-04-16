{ config, pkgs, lib, ... }:

{
  home-manager.users.mortiferus = { config, ... }: {
    programs.home-manager.enable = true; # [cite: 87]

    # MangoHud Block wurde entfernt, da er nun über die gaming.nix 
    # und die globale Config in system.nix gesteuert wird. [cite: 88]

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
