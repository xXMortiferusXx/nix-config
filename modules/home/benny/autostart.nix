# systemd-user-Services für benny
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
  systemd.user.tmpfiles.rules = [
    # obexd (BT-Dateiübertragung) braucht den Root-Ordner
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
        # waitForTray wartet auf Noctalia; 90s-Standard reichen beim langsamen iGPU-Login nicht.
        TimeoutStartSec = "5min";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
    # Steam auf benny bewusst nicht starten (langsamer iGPU-Login).
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
        TimeoutStartSec = "5min";
        Restart = "on-failure";
      };
    };
  };
}
