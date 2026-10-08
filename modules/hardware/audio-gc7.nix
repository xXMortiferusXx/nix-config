# Creative Sound Blaster GC7: GameVoice-Mix + 7.1 via zwei USB-Playback-Streams
# (Game 7.1 + Voice/Chat + Mic); Clock-Raten, pro-audio-Profil und S3-Fix unten.
{ pkgs, ... }:

{
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
      # Kein Samplerate-Pin: GC7 liefert nativ 48k/96k/192k (HiRes).
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

  # Nach Resume GC7 hart zurücksetzen + WirePlumber neu starten.
  powerManagement.resumeCommands = ''
    for d in /sys/bus/usb/devices/*/idVendor; do
      if [ "$(cat "$d" 2>/dev/null)" = "041e" ] && [ "$(cat "''${d%idVendor}idProduct" 2>/dev/null)" = "3271" ]; then
        dev="''${d%/idVendor}"
        bus="$(cat "$dev/busnum" 2>/dev/null)"
        num="$(cat "$dev/devnum" 2>/dev/null)"
        if [ -n "$bus" ] && [ -n "$num" ] && [ -e "/dev/bus/usb/$bus/$num" ]; then
          ${pkgs.usbutils}/bin/usbreset "/dev/bus/usb/$bus/$num" >/dev/null 2>&1 || true
        fi
      fi
    done
    sleep 2
    runuser -u mortiferus -- env XDG_RUNTIME_DIR=/run/user/1000 systemctl --user restart wireplumber || true
  '';
}
