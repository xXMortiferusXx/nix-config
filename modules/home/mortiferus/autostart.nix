# systemd-user-Services für mortiferus (nex)
# Start nach graphical-session.target + noctalia.service
{ config, pkgs, lib, ... }:

let
  extraCompatPaths = lib.makeSearchPathOutput "steamcompattool" "" [ pkgs.proton-ge-bin ];

  # chatduck — Auto-Ducking für Game/Chat-Audio (in den Nix Store für echte Reproduzierbarkeit)
  chatduck = pkgs.writeScriptBin "chatduck" (builtins.readFile ../../../home/mortiferus/config/bin/chatduck);

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


  steamPackage = pkgs.steam.override {
    extraPkgs = pkgs: with pkgs; [
      mangohud
      bibata-cursors
    ];
    extraEnv = {
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";
    };
    extraProfile = "unset TZ";
  };
in
{
  systemd.user.tmpfiles.rules = [
    "L+ %h/.local/share/Steam/compatibilitytools.d/GE-Proton-Latest - - - - ${lib.getOutput "steamcompattool" pkgs.proton-ge-bin}"
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
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
    steam = {
      Unit = {
        Description = "Steam";
        After = [ "graphical-session.target" "noctalia.service" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        Environment = [
          "STEAM_EXTRA_COMPAT_TOOLS_PATHS=${extraCompatPaths}"
          "XCURSOR_THEME=Bibata-Modern-Ice"
          "XCURSOR_SIZE=24"
        ];
        ExecStartPre = [ waitForTray ];
        ExecStart = "${steamPackage}/bin/steam";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
    udiskie = {
      Unit = {
        Description = "udiskie – automounter";
        After = [ "graphical-session.target" "noctalia.service" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.udiskie}/bin/udiskie";
        Restart = "on-failure";
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
    chatduck = {
      Unit = {
        Description = "Chatduck — Auto-Ducking für Game/Chat-Audio";
        After = [ "graphical-session.target" "pipewire.service" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${chatduck}/bin/chatduck";
        Restart = "on-failure";
        RestartSec = 3;
        Environment = "CHATDUCK_DUCK_VOL=0.60";
      };
    };

  };
}
