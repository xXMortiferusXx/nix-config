{ config, pkgs, ... }:

{
  home.file.".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";

  xdg.configFile = {
    "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/backbone/config/niri";
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/backbone/config/nvim";
  };

  # Noctalia v5 verwaltet alle Daten (Config, State, Plugins) unter ~/.local/state/noctalia.
  # ~/.config/noctalia wird von v5 nicht mehr genutzt.
  home.file.".local/state/noctalia".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/backbone/state/noctalia";
}
