# Creative Sound Blaster GC7 (USB 041e:3271) — Hardware-GameVoice-Mix + 7.1
#
# Der GC7 stellt ZWEI getrennte USB-Playback-Streams bereit, die der
# physische GameVoice-Mix-Drehknopf in Hardware mischt:
#   - Interface 4 (PCM 0, bis 8ch)  = Game-Audio  -> "GC7 Game (7.1)"
#   - Interface 6 (PCM 1, 2ch 48k)  = Voice/Chat   -> "GC7 Voice (Chat)"
#   - Interface 5 (PCM 0 capture)   = analoges Mic -> "GC7 Microphone"
#
# Damit beide Streams gleichzeitig offen sind, muss das Gerät auf das
# Profil "pro-audio" gestellt sein (Index 24). Das ACP-Surround-Profil
# öffnet nur Interface 4 -> der GameVoice-Knopf hätte dann nichts zu mischen.
#
# Pro Audio vergibt zunächst generische Kanal-Labels (AUX0..AUX7). Deshalb
# setzen wir die Positionen explizit: der 8ch-Game-Stream wird als echtes
# 7.1 deklariert (USB-Descriptor bmChannelConfig=0x63f => FL,FR,FC,LFE,BL,BR,SL,SR),
# sonst erkennen Spiele/Wine/Proton kein 7.1 (sie sehen "8x unbekannt").
# Die Profilwahl persistiert WirePlumber selbst (State).
{ pkgs, ... }:

{
  services.pipewire.wireplumber.extraConfig."90-gc7" = {
    # Profilwahl deklarativ: erzwungen auf "pro-audio" (sonst wählt WP bei leerem
    # State das höchste ACP-Profil und überspringt pro-audio bewusst -> kein Voice-
    # Stream = kein ChatMix). Gilt auch nach Neuinstallation ohne gespeicherten State.
    "device.profile.priority.rules" = [
      {
        matches = [ { "device.name" = "~alsa_card.usb.*Sound_Blaster_GC7.*"; } ];
        actions."update-props"."priorities" = [ "pro-audio" ];
      }
    ];

    "monitor.alsa.rules" = [
      # KEIN Samplerate-Pin (bewusst): Der GC7 bietet nativ 48k/96k/192k (HiRes).
      # WirePlumber waehlt automatisch den zur Anwendung passenden Altset/Rate.
      # Ein Pin auf 48k wuerde das Geraet deckeln — HiRes ist ohne HW-Schalter
      # allein Sache des Treibers/Streams, also einfach die App auf 96/192k
      # stellen, dann folgt die Karte.
      #
      # session.suspend-timeout-seconds = 0: Nodes NIE einschlafen lassen.
      # Sonst suspendet PipeWire sie nach ~5s Stille und beim Reaktivieren
      # (z. B. Discord-Mic wenn der Kollege spricht) muss der GC7 seinen
      # UAC-Clock neu verhandeln -> Timeout ("Start error: Wartezeit
      # abgelaufen") -> hohes Knacken/Stoerung. Gleiche Ursache/Kur wie beim
      # GameDAC (Commit 9235fa9). Bewusst fuer Output UND Capture.
      {
        matches = [ { "node.name" = "~alsa_output.*Sound_Blaster_GC7.*pro-output-0$"; } ];
        actions."update-props" = {
          "node.description" = "GC7 Game (7.1)";
          "audio.channels" = 8;
          "audio.position" = [ "FL" "FR" "FC" "LFE" "RL" "RR" "SL" "SR" ];
          "session.suspend-timeout-seconds" = 0;
        };
      }
      {
        matches = [ { "node.name" = "~alsa_output.*Sound_Blaster_GC7.*pro-output-1$"; } ];
        actions."update-props" = {
          "node.description" = "GC7 Voice (Chat)";
          "audio.channels" = 2;
          "audio.position" = [ "FL" "FR" ];
          "session.suspend-timeout-seconds" = 0;
        };
      }
      {
        matches = [ { "node.name" = "~alsa_input.*Sound_Blaster_GC7.*pro-input-0$"; } ];
        actions."update-props" = {
          "node.description" = "GC7 Microphone";
          "audio.channels" = 2;
          "audio.position" = [ "FL" "FR" ];
          "session.suspend-timeout-seconds" = 0;
        };
      }
    ];
  };

  # Standby-Fix: Nach S3-Resume hängt der GC7 (UAC-Clock tot, "cannot get freq:
  # err -110", "clock source 37 is not valid") -> weder Ton noch Mic bis zum
  # manuellen Replug. Ursache: USB-Autosuspend (power/control=auto) -> der Port
  # wird nach dem Wake nicht sauber re-initialisiert.
  #
  # (1) Autosuspend für das Gerät deaktivieren (bleibt im laufenden Betrieb wach;
  #     im S3 geht es physikalisch trotzdem aus, das ist normal).
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="041e", ATTR{idProduct}=="3271", ATTR{power/control}="on"
  '';

  # VERWORFEN (2026-10-02): implicit_fb=1 fuer den GC7.
  #   options snd-usb-audio vid=0x041e pid=0x3271 implicit_fb=1
  # Nach Reboot versuchsweise aktiviert -> Discord-Stimmen klangen sofort wie
  # Roboter (total verzerrt). Der GC7 hat offenbar ein EIGENES Feedback und darf
  # nicht in den generischen impliziten Sync-Modus gezwungen werden. NICHT wieder
  # einbauen. (Das urspruengliche, seltene Knacken ist damit weiterhin offen und
  # kommt nicht aus dem aufgenommenen Signalfluss - siehe memory.md.)

  # (2) Sicherheitsnetz beim Aufwachen: GC7 hart zurücksetzen + WirePlumber neu
  #     aufbauen -> Ton/Mic kommen ohne manuelles Replug zurück.
  #     powerManagement.enable ist auf nex bereits über nvidia-prime.nix aktiv.
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
