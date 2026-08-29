{ config, pkgs, lib, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Arctis Sound Manager (SteelSeries GG/Sonar-Ersatz) — verwaltet EQ/ChatMix/Virtual Surround
  services.arctis-sound-manager.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;

    extraConfig.pipewire."99-lowlatency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 2048;
      };
      "pulse.properties" = {
        "pulse.min.quantum" = "256/48000";
      };
    };
  };

  # LADSPA_PATH fuer PipeWire filter-chain (LADSPA-Plugins wie Kompressor)
  # WICHTIG: Das NixOS pipewire-Modul setzt LADSPA_PATH hardcoded auf sein eigenes
  # leeres pipewire-ladspa-plugins Paket. Wir überschreiben das hier explizit
  # in der systemd Unit, damit Steve Harris Plugins (sc2_1426) geladen werden.
  systemd.user.services.pipewire.environment.LADSPA_PATH = lib.mkForce "${pkgs.ladspaPlugins}/lib/ladspa";

  environment.systemPackages = with pkgs; [
    pavucontrol
    qpwgraph
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
