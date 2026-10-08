# systemd-user-Services für mortiferus (nex)
# Start nach graphical-session.target + noctalia.service
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
  # Unterdrückt den Paket-eigenen XDG-Autostart-Eintrag des polychromatic-Pakets
  # (per-user-Profil: /etc/profiles/per-user/mortiferus/etc/xdg/autostart).
  # Der Tray-Applet wird hier über polychromatic-tray.service gestartet, das die
  # waitForTray-Reihenfolge + Restart über systemd bekommt. Der XDG-Eintrag liefe
  # zeitgleich über xdg-desktop-autostart.target (umbriel-session.target: Wants) und
  # würde per PID-Lock den systemd-verwalteten Applet killen (Restart-Kampf).
  # Hidden=true ist der XDG-Spec-Override: gleicher Name in ~/.config/autostart
  # hat Vorrang vor dem Profil-Pfad.
  xdg.configFile."autostart/polychromatic-autostart.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Polychromatic Autostart
    Hidden=true
  '';

  # Steam-Autostart bewusst NICHT hier: Steam verwaltet seinen Autostart selbst
  # (Einstellungen -> "Steam beim Anmelden starten"), so entscheidet jeder Host
  # individuell. Kein systemd-Service, kein HM-XDG-Eintrag.

  systemd.user.tmpfiles.rules = [
    # obexd (BT-Dateiübertragung) braucht den Root-Ordner, sonst bricht er ab
    # (exit 1 → start-limit-hit). Automatisch bei jedem Login / Neuinstallation anlegen.
    "d %h/Downloads/Bluetooth 0755 - - -"
  ];

  systemd.user.services = {
    discord = {
      Unit = {
        Description = "Discord";
        After = [ "graphical-session.target" "noctalia.service" ];
        # Discord registriert sein SNI-Tray nur beim Start und nicht erneut.
        # Wird Noctalia neu gestartet (z. B. nix-sync), verschwindet das Icon
        # dauerhaft -> Discord bei Noctalia-Neustart mit-neu-starten.
        PartOf = [ "noctalia.service" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStartPre = [ waitForTray ];
        ExecStart = "${pkgs.discord}/bin/discord";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
    polychromatic-tray = {
      Unit = {
        Description = "Polychromatic Tray";
        After = [ "graphical-session.target" "noctalia.service" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.polychromatic}/bin/polychromatic-tray-applet";
        Restart = "on-failure";
      };
    };
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
