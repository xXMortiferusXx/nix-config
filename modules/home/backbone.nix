{ config, pkgs, lib, ... }:

{
  home-manager.users.backbone = { config, ... }: {
    programs.home-manager.enable = true;

    home.packages = with pkgs; [
      # Icons & Cursors
      papirus-icon-theme
      adwaita-icon-theme
      bibata-cursors

      # Tools & Office
      libreoffice
      hunspellDicts.de_DE
      hyphenDicts.de-de
      yazi
      btop
      kitty
      nautilus
      
      # Dokumente & Bilder
      zathura
      loupe
    ];

    home.file.".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";

    xdg.configFile = {
      "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/backbone/config/niri";
      "noctalia".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/backbone/config/noctalia";
      #"pipewire".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/pipewire";
      "nvim".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/backbone/config/nvim";
    };

    home.username = "backbone";
    home.homeDirectory = "/home/backbone";
    home.stateVersion = "25.11";
  };
}
