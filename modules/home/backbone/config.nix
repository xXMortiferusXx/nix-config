{ config, pkgs, lib, ... }:

{
  home.file.".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";

  xdg.configFile = {
    "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/backbone/config/niri";
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/backbone/config/nvim";
  };

  # Noctalia v5 verwaltet alle Daten (Config, State, Plugins) unter ~/.local/state/noctalia.
  # ~/.config/noctalia wird von v5 nicht mehr genutzt.
  # ACHTUNG: home.file wuerde den Symlink bei jedem Rebuild auf den Store ueberschreiben.
  # Daher wird ein activation-Script verwendet, das den Symlink nach dem HM-Switch setzt.
  home.activation.createNoctaliaState = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Entferne ggf. alten Store-Symlink oder Datei
    if [ -e "$HOME/.local/state/noctalia" ] || [ -L "$HOME/.local/state/noctalia" ]; then
      rm -rf "$HOME/.local/state/noctalia"
    fi
    # Erstelle Symlink aufs Repo (schreibbar, fuer State-Backup)
    ln -sfn /etc/nixos/home/backbone/state/noctalia "$HOME/.local/state/noctalia"
  '';
}
