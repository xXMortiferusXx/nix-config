{ config, pkgs, lib, ... }:

{
  home.file.".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";

  # ACHTUNG: home.file würde den Symlink bei jedem Rebuild auf den Store überschreiben -> activation-Script.
  home.activation.createNoctaliaState = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Entferne ggf. alten Store-Symlink oder Datei
    if [ -e "$HOME/.local/state/noctalia" ] || [ -L "$HOME/.local/state/noctalia" ]; then
      rm -rf "$HOME/.local/state/noctalia"
    fi
    # Erstelle Symlink aufs Repo (schreibbar, fuer State-Backup)
    ln -sfn /etc/nixos/home/backbone/state/noctalia "$HOME/.local/state/noctalia"

    # Erst-Installation: Live-settings.toml aus getrackter Baseline seeden.
    # Danach ist settings.toml lokal (untracked) und wird nie vom Pull ueberschrieben.
    if [ ! -e /etc/nixos/home/backbone/state/noctalia/settings.toml ]; then
      cp /etc/nixos/home/backbone/state/noctalia/settings.toml.baseline \
         /etc/nixos/home/backbone/state/noctalia/settings.toml
    fi
  '';
}
