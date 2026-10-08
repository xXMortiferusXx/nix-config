{ config, pkgs, lib, ... }:

{
  home.file = {
    ".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";

    # GTK 2.0 / Default-Icon-Theme (live editierbar)
    ".gtkrc-2.0".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/lion/config/gtkrc-2.0";
    ".icons/default".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/lion/config/icons/default";
  };

  # ACHTUNG: home.file würde den Symlink bei jedem Rebuild auf den Store überschreiben -> activation-Script.
  home.activation.createNoctaliaState = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Entferne ggf. alten Store-Symlink oder Datei
    if [ -e "$HOME/.local/state/noctalia" ] || [ -L "$HOME/.local/state/noctalia" ]; then
      rm -rf "$HOME/.local/state/noctalia"
    fi
    # Erstelle Symlink aufs Repo (schreibbar, fuer State-Backup)
    ln -sfn /etc/nixos/home/lion/state/noctalia "$HOME/.local/state/noctalia"

    # Erst-Installation: Live-settings.toml aus getrackter Baseline seeden.
    # Danach ist settings.toml lokal (untracked) und wird nie vom Pull ueberschrieben.
    if [ ! -e /etc/nixos/home/lion/state/noctalia/settings.toml ]; then
      cp /etc/nixos/home/lion/state/noctalia/settings.toml.baseline \
         /etc/nixos/home/lion/state/noctalia/settings.toml
    fi
  '';

  # ~/.face via Out-of-Store-Symlink, da accounts-daemon Store-Symlinks nicht lesen kann.
  home.activation.createFaceAvatar = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Entferne ggf. alten Store-Symlink
    if [ -L "$HOME/.face" ]; then
      rm -f "$HOME/.face"
    fi
    # Erstelle Symlink aufs Repo (accounts-daemon kann echten Pfad lesen)
    ln -sfn /etc/nixos/home/lion/assets/face.png "$HOME/.face"
  '';

  # writeBoundary setzt die ACL-Mask auf --- -> greeter braucht Execute-Recht auf $HOME.
  home.activation.fixHomeAclMask = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.acl}/bin/setfacl -m u:greeter:x,m::r-x "$HOME"
  '';
}