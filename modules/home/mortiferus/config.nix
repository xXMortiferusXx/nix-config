{ config, pkgs, lib, ... }:

{
  xdg.configFile = {
    "niri".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/niri";
    "pipewire".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/pipewire";
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/nvim";
    "hypr".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/hypr";

    # GTK/QT Theme-Einstellungen (live editierbar via nwg-look / qt5ct / qt6ct)
    "gtk-3.0/settings.ini".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/gtk-3.0/settings.ini";
    "gtk-4.0/settings.ini".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/gtk-4.0/settings.ini";
    "xsettingsd/xsettingsd.conf".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/xsettingsd/xsettingsd.conf";
    "qt5ct/qt5ct.conf".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/qt5ct/qt5ct.conf";
    "qt6ct/qt6ct.conf".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/qt6ct/qt6ct.conf";
  };

  home.file = {
    ".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";

    # GTK 2.0 / Default-Icon-Theme (live editierbar)
    ".gtkrc-2.0".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/gtkrc-2.0";
    ".icons/default/index.theme".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/mortiferus/config/icons/default/index.theme";
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
    ln -sfn /etc/nixos/home/mortiferus/state/noctalia "$HOME/.local/state/noctalia"
  '';

  # Avatar/Profilbild fuer AccountsService und Noctalia-Greeter.
  # accounts-daemon liest ~/.face automatisch und zeigt es im Login-Screen an.
  # Home-Manager's home.file erzeugt einen Store-Symlink, den accounts-daemon
  # nicht lesen kann. Daher: Out-of-Store-Symlink via activation-Script.
  home.activation.createFaceAvatar = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Entferne ggf. alten Store-Symlink
    if [ -L "$HOME/.face" ]; then
      rm -f "$HOME/.face"
    fi
    # Erstelle Symlink aufs Repo (accounts-daemon kann echten Pfad lesen)
    ln -sfn /etc/nixos/home/mortiferus/assets/face.png "$HOME/.face"
  '';

  # Home-Manager's writeBoundary setzt bei nix-switch die ACL-Mask auf Home auf ---
  # (chmod synchronisiert Mask mit Unix-Gruppenrechten). Das blockiert greeter/accounts-daemon.
  # Daher: Nach writeBoundary dem greeter-User Execute-Recht auf $HOME geben (damit er
  # ~/.face erreicht), und die Mask auf r-x setzen.
  home.activation.fixHomeAclMask = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.acl}/bin/setfacl -m u:greeter:x,m::r-x "$HOME"
  '';
}
