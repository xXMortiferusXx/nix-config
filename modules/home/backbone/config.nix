{ config, pkgs, ... }:

{
  home.file.".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";

  xdg.configFile = {
    "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/backbone/config/niri";
    "noctalia".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/backbone/config/noctalia";
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/backbone/config/nvim";
  };
}
