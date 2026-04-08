{ config, pkgs, ... }:

{
  # Dieses Modul gehört zu Home‑Manager
  home-manager.users.mortiferus = {

    # Home‑Manager aktivieren
    programs.home-manager.enable = true;

    # XDG-Config-Ordner verlinken
    xdg.configFile = {
      #"niri".source = ../home/mortiferus/config/niri;
    };

    # User-Informationen
    home.username = "mortiferus";
    home.homeDirectory = "/home/mortiferus";

    # Home-Manager Version
    home.stateVersion = "25.11";
  };
}

