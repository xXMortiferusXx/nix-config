{ config, pkgs, lib, ... }:

{
  # ~/.config als system-level bind-mounts (hosts/benny/config-mounts.nix).
  home.file = {
    ".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";

    # GTK 2.0 / Default-Icon-Theme (live editierbar)
    ".gtkrc-2.0".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/benny/config/gtkrc-2.0";
    ".icons/default".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/benny/config/icons/default";
  };

  # ACHTUNG: home.file würde den Symlink bei jedem Rebuild auf den Store überschreiben -> activation-Script.
  home.activation.createNoctaliaState = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Entferne ggf. alten Store-Symlink oder Datei
    if [ -e "$HOME/.local/state/noctalia" ] || [ -L "$HOME/.local/state/noctalia" ]; then
      rm -rf "$HOME/.local/state/noctalia"
    fi
    # Erstelle Symlink aufs Repo (schreibbar, fuer State-Backup)
    ln -sfn /etc/nixos/home/benny/state/noctalia "$HOME/.local/state/noctalia"

    # Erst-Installation: Live-settings.toml aus getrackter Baseline seeden.
    # Danach ist settings.toml lokal (untracked) und wird nie vom Pull ueberschrieben.
    if [ ! -e /etc/nixos/home/benny/state/noctalia/settings.toml ]; then
      cp /etc/nixos/home/benny/state/noctalia/settings.toml.baseline \
         /etc/nixos/home/benny/state/noctalia/settings.toml
    fi
  '';

  # Avatar/Profilbild fuer AccountsService und Noctalia-Greeter.
  home.activation.createFaceAvatar = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -L "$HOME/.face" ]; then
      rm -f "$HOME/.face"
    fi
    ln -sfn /etc/nixos/home/benny/assets/face.png "$HOME/.face"
  '';

  # greeter-User braucht Execute-Recht auf $HOME (siehe lion/config.nix).
  home.activation.fixHomeAclMask = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.acl}/bin/setfacl -m u:greeter:x,m::r-x "$HOME"
  '';
}
