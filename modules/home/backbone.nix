{ config, pkgs, lib, ... }:

{
  home-manager.users.backbone = { config, ... }: {
    programs.home-manager.enable = true;

    home.packages = with pkgs; [
      # Icons & Cursors
      papirus-icon-theme
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
        name = "Papirus";
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
      };
    };

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
