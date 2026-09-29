# Creative Sound Blaster GC7 (USB 041e:3271) — Hardware-GameVoice-Mix + 7.1
#
# Der GC7 stellt ZWEI getrennte USB-Playback-Streams bereit, die der
# physische GameVoice-Mix-Drehknopf in Hardware mischt:
#   - Interface 4 (PCM 0, bis 8ch)  = Game-Audio  -> "GC7 Game (7.1)"
#   - Interface 6 (PCM 1, 2ch 48k)  = Voice/Chat   -> "GC7 Voice (Chat)"
#   - Interface 5 (PCM 0 capture)   = analoges Mic -> "GC7 Microphone"
#
# Damit beide Streams gleichzeitig offen sind, muss das Gerät auf das
# Profil "pro-audio" gestellt sein (Profil-Index 24). Das ACP-Surround-Profil
# öffnet nur Interface 4 -> der GameVoice-Knopf hätte dann nichts zu mischen.
# Die Profilwahl persistiert WirePlumber selbst (State); hier benennen wir
# nur die Nodes für die Geräteauswahl in Discord/Desktops um.
{ ... }:

{
  services.pipewire.wireplumber.extraConfig."90-gc7-names" = {
    "monitor.alsa.rules" = [
      {
        matches = [ { "node.name" = "~alsa_output.*Sound_Blaster_GC7.*pro-output-0$"; } ];
        actions."update-props"."node.description" = "GC7 Game (7.1)";
      }
      {
        matches = [ { "node.name" = "~alsa_output.*Sound_Blaster_GC7.*pro-output-1$"; } ];
        actions."update-props"."node.description" = "GC7 Voice (Chat)";
      }
      {
        matches = [ { "node.name" = "~alsa_input.*Sound_Blaster_GC7.*pro-input-0$"; } ];
        actions."update-props"."node.description" = "GC7 Microphone";
      }
    ];
  };
}
