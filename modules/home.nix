{ config, pkgs, ... }:

{
  # Dieses Modul gehört zu Home‑Manager
  home-manager.users.mortiferus = {

    # Home‑Manager aktivieren
    programs.home-manager.enable = true;

    # XDG-Config-Ordner verlinken
    xdg.configFile = {
      "niri".source = ../home/mortiferus/config/niri;
      "noctalia".source = ../home/mortiferus/config/noctalia;
      "yazi".source = ../home/mortiferus/config/yazi;
      "zathura".source = ../home/mortiferus/config/zathura;
      "gtk-3.0".source = ../home/mortiferus/config/gtk-3.0;
      "gtk-4.0".source = ../home/mortiferus/config/gtk-4.0;
      "qt5ct".source = ../home/mortiferus/config/qt5ct;
      "qt6ct".source = ../home/mortiferus/config/qt6ct;
    };

    # User-Informationen
    home.username = "mortiferus";
    home.homeDirectory = "/home/mortiferus";

    # Home-Manager Version
    home.stateVersion = "25.11";
  };
}

