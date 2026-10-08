# Creative Sound Blaster GC7: GameVoice-Mix + 7.1 via zwei USB-Playback-Streams
# (Game 7.1 + Voice/Chat + Mic); Clock-Raten, pro-audio-Profil und Lock-Fix.
{ pkgs, ... }:

let
  # Software-"Replug": toggelt den USB-Port (bzw. authorized), damit ein
  # hart-gelocktes GC7 ohne physisches Abstecken zurückkommt. Ein Warm-Reboot
  # power-cyclet USB nicht -> sonst bleibt es nach dem Lock hängen.
  # --if-missing: nur handeln, wenn das GC7 fehlt (Boot-Service).
  gc7Reset = pkgs.writeShellScriptBin "gc7-reset" ''
    export PATH="${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.systemd pkgs.util-linux ]}:$PATH"
    set -u
    if_missing=0
    [ "''${1:-}" = "--if-missing" ] && if_missing=1

    found=""
    for d in /sys/bus/usb/devices/*/idVendor; do
      [ "$(cat "$d" 2>/dev/null)" = "041e" ] || continue
      [ "$(cat "''${d%idVendor}idProduct" 2>/dev/null)" = "3271" ] || continue
      found="''${d%idVendor}"
    done

    if [ -n "$found" ]; then
      [ "$if_missing" = 1 ] && exit 0
      echo "gc7-reset: GC7 bei $found -> authorized 0/1"
      echo 0 > "''${found}authorized" 2>/dev/null || true
      sleep 1
      echo 1 > "''${found}authorized" 2>/dev/null || true
      sleep 2
    else
      # Nicht enumeriert -> leere Ports des GC7-Controllers (usb3) toggeln.
      for port in /sys/bus/usb/devices/usb3/*-0:1.0/usb3-port*; do
        [ -e "$port/disable" ] || continue
        n="''${port##*-port}"
        [ -e "/sys/bus/usb/devices/3-$n" ] && continue
        echo "gc7-reset: GC7 fehlt -> Port $port toggeln"
        echo 1 > "$port/disable" 2>/dev/null || true
        sleep 1
        echo 0 > "$port/disable" 2>/dev/null || true
      done
      sleep 2
    fi

    [ "$if_missing" = 1 ] && exit 0
    uid="$(id -u mortiferus 2>/dev/null || echo 1000)"
    runuser -u mortiferus -- env XDG_RUNTIME_DIR="/run/user/$uid" \
      systemctl --user restart wireplumber >/dev/null 2>&1 || true
  '';
in
{
  environment.systemPackages = [ gc7Reset ];

  # Erlaubte Clock-Raten systemweit erweitern (sonst werden 44100/88200/...
  # zwangsresampled -> Knacken). Kein Deckel, 48000 bleibt Default.
  services.pipewire.extraConfig.pipewire."99-gc7-clock" = {
    "context.properties"."default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];
    "context.properties"."default.clock.rate" = 48000;
  };

  services.pipewire.wireplumber.extraConfig."90-gc7" = {
    # Profil "pro-audio" erzwingen (sonst kein Voice-Stream = kein ChatMix).
    "device.profile.priority.rules" = [
      {
        matches = [ { "device.name" = "~alsa_card.usb.*Sound_Blaster_GC7.*"; } ];
        actions."update-props"."priorities" = [ "pro-audio" ];
      }
    ];

    "monitor.alsa.rules" = [
      # session.suspend-timeout-seconds = 0: Nodes nie einschlafen, sonst
      # UAC-Clock-Timeout -> Knacken (bewusst fuer Output UND Capture).
      {
        matches = [ { "node.name" = "~alsa_output.*Sound_Blaster_GC7.*pro-output-0$"; } ];
        actions."update-props" = {
          "node.description" = "GC7 Game (7.1)";
          "audio.channels" = 8;
          "audio.position" = [ "FL" "FR" "FC" "LFE" "RL" "RR" "SL" "SR" ];
          "session.suspend-timeout-seconds" = 0;
          "api.alsa.headroom" = 512;
        };
      }
      {
        matches = [ { "node.name" = "~alsa_output.*Sound_Blaster_GC7.*pro-output-1$"; } ];
        actions."update-props" = {
          "node.description" = "GC7 Voice (Chat)";
          "audio.channels" = 2;
          "audio.position" = [ "FL" "FR" ];
          "session.suspend-timeout-seconds" = 0;
          "api.alsa.headroom" = 512;
        };
      }
      {
        matches = [ { "node.name" = "~alsa_input.*Sound_Blaster_GC7.*pro-input-0$"; } ];
        actions."update-props" = {
          "node.description" = "GC7 Microphone";
          "audio.channels" = 2;
          "audio.position" = [ "FL" "FR" ];
          "session.suspend-timeout-seconds" = 0;
          "api.alsa.headroom" = 512;
        };
      }
    ];
  };

  # Autosuspend aus: GC7 hängt sonst nach S3-Resume (UAC-Clock tot) bis zum Replug.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="041e", ATTR{idProduct}=="3271", ATTR{power/control}="on"
  '';

  # implicit_fb=1 NICHT setzen (macht Discord-Stimmen roboterhaft/verzerrt).

  # Nach Resume GC7 per Software-Replug zurücksetzen + WirePlumber neu starten.
  powerManagement.resumeCommands = ''
    ${gc7Reset}/bin/gc7-reset || true
  '';

  # Boot: hängt das GC7 noch vom letzten Lock fest, Port einmal toggeln.
  systemd.services.gc7-reenum = {
    description = "GC7 re-enumerate if missing";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${gc7Reset}/bin/gc7-reset --if-missing";
    };
  };
}
