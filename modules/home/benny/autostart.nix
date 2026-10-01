# systemd-user-Services für benny
# Start nach graphical-session.target + noctalia.service
{ config, pkgs, lib, ... }:

let
  extraCompatPaths = lib.makeSearchPathOutput "steamcompattool" "" [ pkgs.proton-ge-bin ];

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

  steamPackage = pkgs.steam.override {
    extraPkgs = pkgs: with pkgs; [
      mangohud
      bibata-cursors
      pulseaudio
      libusb1
    ];
    extraEnv = {
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";
      XCURSOR_PATH = "/usr/share/icons:/usr/local/share/icons:$HOME/.icons:$HOME/.local/share/icons";
    };
    extraProfile = "unset TZ";
  };
in
{
  systemd.user.tmpfiles.rules = [
    "L+ %h/.local/share/Steam/compatibilitytools.d/GE-Proton-Latest - - - - ${lib.getOutput "steamcompattool" pkgs.proton-ge-bin}"
    # obexd (BT-Dateiübertragung) braucht den Root-Ordner
    "d %h/Downloads/Bluetooth 0755 - - -"
  ];

  systemd.user.services = {
    discord = {
      Unit = {
        Description = "Discord";
        After = [ "graphical-session.target" "noctalia.service" ];
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
    # Steam wird NICHT mehr automatisch gestartet (Benny ist auf dem
    # Intel-iGPU-System ohnehin langsam beim Login). Unit bleibt definiert und
    # kann bei Bedarf manuell gestartet werden: `systemctl --user start steam`.
    steam = {
      Unit = {
        Description = "Steam";
        After = [ "graphical-session.target" "noctalia.service" ];
      };
      Service = {
        Environment = [
          "STEAM_EXTRA_COMPAT_TOOLS_PATHS=${extraCompatPaths}"
          "XCURSOR_THEME=Bibata-Modern-Ice"
          "XCURSOR_SIZE=24"
        ];
        ExecStartPre = [ waitForTray ];
        ExecStart = "${steamPackage}/bin/steam";
        TimeoutStartSec = "5min";
        Restart = "on-failure";
        RestartSec = 10;
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
        TimeoutStartSec = "5min";
        Restart = "on-failure";
      };
    };
  };
}
