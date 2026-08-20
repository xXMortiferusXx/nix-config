{ config, pkgs, lib, ... }:

{
  home.file.".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";

  # xdg.configFile-Einträge entfernt (2026-08-20):
  # ~/.config-Verzeichnisse werden jetzt als system-level bind-mounts bereitgestellt
  # (hosts/styx/config-mounts.nix). Damit funktionieren FHS-Sandbox-Apps ohne
  # Symlink-Auflösung über /etc/nixos.

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
