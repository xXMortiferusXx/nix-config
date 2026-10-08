# systemd-user-Services für mortiferus (nex)
# Start nach graphical-session.target + noctalia.service
{ pkgs, ... }:

let
  # Warten bis Noctalia den SNI-Tray-Watcher registriert hat (Electron-Apps registrieren ihr Tray nur einmal).
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
  # Hidden=true unterdrückt den XDG-Autostart des polychromatic-Pakets (sonst PID-Lock-Kampf mit dem systemd-Service).
  xdg.configFile."autostart/polychromatic-autostart.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Polychromatic Autostart
    Hidden=true
  '';

  # Kein Steam-Autostart: Steam verwaltet das selbst (host-individuell).

  systemd.user.tmpfiles.rules = [
    # obexd braucht den Root-Ordner, sonst exit 1 -> start-limit-hit.
    "d %h/Downloads/Bluetooth 0755 - - -"
  ];

  systemd.user.services = {
    discord = {
      Unit = {
        Description = "Discord";
        After = [ "graphical-session.target" "noctalia.service" ];
        # Discord registriert sein SNI-Tray nur beim Start -> bei Noctalia-Neustart mit-neu-starten.
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
