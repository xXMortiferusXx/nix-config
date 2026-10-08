# systemd-user-Services für benny
# Start nach graphical-session.target + noctalia.service
{ pkgs, ... }:

let
  # SNI-Tray-Watcher wird von noctalia erst nach dem Start registriert.
  # Electron-Apps registrieren ihr Tray nur einmal → vor App-Start warten.
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
        # waitForTray wartet auf Noctalia; Standard-90s reichen beim langsamen
        # iGPU-Login nicht immer -> großzügiger Start-Timeout.
        TimeoutStartSec = "5min";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
    # Steam wird auf benny bewusst NICHT gestartet (Intel-iGPU, langsamer
    # Login) — bei Bedarf regulär per Launcher/Terminal starten.
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
