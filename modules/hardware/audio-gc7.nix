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
{ ... }:

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
      {
        matches = [ { "node.name" = "~alsa_output.*Sound_Blaster_GC7.*pro-output-0$"; } ];
        actions."update-props" = {
          "node.description" = "GC7 Game (7.1)";
          "audio.channels" = 8;
          "audio.position" = [ "FL" "FR" "FC" "LFE" "RL" "RR" "SL" "SR" ];
        };
      }
      {
        matches = [ { "node.name" = "~alsa_output.*Sound_Blaster_GC7.*pro-output-1$"; } ];
        actions."update-props" = {
          "node.description" = "GC7 Voice (Chat)";
          "audio.channels" = 2;
          "audio.position" = [ "FL" "FR" ];
        };
      }
      {
        matches = [ { "node.name" = "~alsa_input.*Sound_Blaster_GC7.*pro-input-0$"; } ];
        actions."update-props" = {
          "node.description" = "GC7 Microphone";
          "audio.channels" = 2;
          "audio.position" = [ "FL" "FR" ];
        };
      }
    ];
  };
}
