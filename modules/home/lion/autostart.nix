# systemd-user-Services für lion (lion-pc)
# Start nach graphical-session.target + noctalia.service
# Ohne polychromatic-tray (kein Razer auf lion-pc), ohne HRIR/pipewire-Spezial.
{ pkgs, ... }:

let
  # SNI-Tray-Watcher (org.kde.StatusNotifierWatcher) wird von noctalia erst
  # registriert, NACHDEM noctalia wirklich läuft (noctalia.service ist
  # Type=simple, systemd meldet "started" sofort beim Exec). Electron-Apps
  # (Discord) registrieren ihr Tray-Item aber nur EINMAL beim Start und nie
  # nach – starten sie vor dem Watcher, fehlt das Systray-Icon dauerhaft.
  # → Vor dem App-Start warten, bis der Watcher wirklich bereit ist.
  waitForTray = pkgs.writeShellScript "wait-for-tray" ''
    until ${pkgs.systemd}/bin/busctl --user get-property \
      org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
      org.kde.StatusNotifierWatcher IsStatusNotifierHostRegistered \
      2>/dev/null | ${pkgs.gnugrep}/bin/grep -q 'b true'; do
      ${pkgs.coreutils}/bin/sleep 0.3
    done
  '';

in
{
  # Steam regulär per XDG-Autostart (kein systemd-Service mehr) -> normaler
  # Prozess, von ProtonPlus/Nutzer sauber beend- und neu startbar.
  xdg.configFile."autostart/steam.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Steam
    Comment=Steam-Spiele verwalten und spielen
    Exec=steam -silent
    Icon=steam
    Terminal=false
    X-GNOME-Autostart-enabled=true
  '';

  systemd.user.tmpfiles.rules = [
    # obexd (BT-Dateiübertragung) braucht den Root-Ordner, sonst bricht er ab
    # (exit 1 → start-limit-hit). Automatisch bei jedem Login / Neuinstallation anlegen.
    "d %h/Downloads/Bluetooth 0755 - - -"
  ];

  systemd.user.services = {
    # Discord vorerst deaktiviert — lion nutzt es noch nicht, wird erst
    # zur Nutzung hingefuehrt. Später aktivieren (restlichen Block entkommentieren).
    # discord = {
    #   Unit = {
    #     Description = "Discord";
    #     After = [ "graphical-session.target" "noctalia.service" ];
    #   };
    #   Install = {
    #     WantedBy = [ "graphical-session.target" ];
    #   };
    #   Service = {
    #     ExecStartPre = [ waitForTray ];
    #     ExecStart = "${pkgs.discord}/bin/discord";
    #     Restart = "on-failure";
    #     RestartSec = 5;
    #   };
    # };
    obex = {
      Unit = {
        Description = "Bluetooth OBEX File Transfer";
        After = [ "graphical-session.target" "noctalia.service" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.bluez}/libexec/bluetooth/obexd --auto-accept --root=%h/Downloads/Bluetooth";
        Type = "dbus";
        BusName = "org.bluez.obex";
        Restart = "on-failure";
      };
    };
  };
}