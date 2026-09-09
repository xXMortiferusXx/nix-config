{ config, pkgs, lib, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Arctis Sound Manager ist nex-only → Aktivierung in hosts/nex/configuration.nix

  # Kein globales 99-lowlatency (Clock/Quantum) mehr: ASM regelt die Latency
  # seiner eigenen filter-chain-Kette selbst (node.latency/node.lock-quantum,
  # pipewire_quantum-Setting). Globales Quantum 512/48k zog nur alle Sinks
  # (notebook-speakers) unnötig runter — die laufen jetzt auf PipeWire-Standard.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  

  environment.systemPackages = with pkgs; [
    pavucontrol
    ladspaPlugins
    alsa-utils
  ];

  # ===========================================================================
  # TEMPORÄR DEAKTIVIERT (2026-08-29): Custom GameDAC-ALSA-Profil.
  # Grund: Test des Arctis-Sound-Manager (verwaltet EQ/ChatMix/Surround selbst).
  # Zum Reaktivieren den /* ... */ Block-Kommentar entfernen.
  # ===========================================================================
  /*
  environment.etc = {
    "alsa-card-profile/mixer/profile-sets/steelseries-gamedac-usb-audio.conf".text = ''
      [General]
      auto-profiles = yes

      [Mapping analog-mic]
      description = Mic
      device-strings = hw:%f,0,0
      channel-map = mono
      paths-input = analog-input-mic
      paths-output =

      [Mapping analog-chat]
      description = Chat
      device-strings = hw:%f,0,0
      channel-map = left,right
      paths-input =
      paths-output = steelseries-gamedac-output-chat

      [Mapping analog-game]
      description = Game
      device-strings = hw:%f,1,0
      channel-map = front-left,front-right,front-center,lfe,rear-left,rear-right
      paths-output = steelseries-gamedac-output-game
      direction = output

      [Profile output:analog-chat+output:analog-game+input:analog-chat]
      output-mappings = analog-chat analog-game
      input-mappings = analog-mic
      priority = 5100
      skip-probe = yes
    '';

    "alsa-card-profile/mixer/paths/steelseries-gamedac-output-game.conf".text = ''
      [General]
      priority = 99

      [Element PCM]
      switch = mute
    '';

    "alsa-card-profile/mixer/paths/steelseries-gamedac-output-chat.conf".text = ''
      [General]
      priority = 50

      [Element Com Speaker]
      switch = mute
    '';

    "alsa-card-profile/mixer/paths/steelseries-gamedac-input.conf".text = ''
      [General]
      description-key = analog-input-microphone-headset

      [Element Headset]
      switch = mute
      override-map.1 = all
      override-map.2 = all-left,all-right
    '';

    "wireplumber/wireplumber.conf.d/51-gamedac-profiles.conf".text = ''
      monitor.alsa.rules = [
        {
          matches = [
            {
              device.name = "~alsa_card.usb-SteelSeries_SteelSeries_GameDAC*"
            }
          ]
          actions = {
            update-props = {
              api.alsa.use-acp = true
              device.profile-set = "steelseries-gamedac-usb-audio.conf"
              device.profile = "output:analog-chat+output:analog-game+input:analog-chat"
            }
          }
        }
      ]
    '';
  };
*/
}
