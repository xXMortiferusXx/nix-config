{ config, pkgs, ... }:

{
  home.file.".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";

  xdg.configFile = {
    "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/niri";
    "noctalia".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/noctalia";
    "pipewire".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/pipewire";
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/nvim";
    "hypr".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/hypr";
  };
}
