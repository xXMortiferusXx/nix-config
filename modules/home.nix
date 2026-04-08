{ config, pkgs, lib, ... }:

{
  # Home-Manager Konfiguration für Mortiferus
  home-manager.users.mortiferus = { config, ... }: {

    # Home-Manager aktivieren
    programs.home-manager.enable = true;

    # XDG-Config-Ordner verlinken (Live-Editierbar & im Git gesichert)
    xdg.configFile = {
      # 1. Fenstermanager & Regeln
      "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/niri";
      
      # 2. Design-System & UI-Elemente
      "noctalia".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/noctalia";
      
      # 3. Gaming-Overlay (FPS, Sensoren, CPU/GPU Last)
      "MangoHud".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/MangoHud";
    };

    # User-Informationen
    home.username = "mortiferus";
    home.homeDirectory = "/home/mortiferus";

    # Versionierung (Beibehalten)
    home.stateVersion = "25.11";
  };
}
