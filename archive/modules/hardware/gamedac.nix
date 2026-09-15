{ config, pkgs, lib, ... }:

{
  # ===========================================================================
  # SteelSeries GameDAC (nur nex): Pro-Audio, minimal
  #
  # NUR pro-audio (roh AUX0–AUX5) + Nie-Suspend. Kein Kanal-Map, kein virtueller
  # Sink — einzige nachweislich knackfreie Variante.
  # ===========================================================================

  # Low-Latency fürs Gaming (Quantum 512 / 48 kHz). Nur für nex (Headset).
  services.pipewire.extraConfig.pipewire."99-lowlatency" = {
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

  environment.etc = {
    "wireplumber/wireplumber.conf.d/51-gamedac-profiles.conf".text = ''
      monitor.alsa.rules = [
        {
          matches = [
            {
              device.name = "~alsa_card.usb-SteelSeries_SteelSeries_GameDAC"
            }
          ]
          actions = {
            update-props = {
              device.profile = "pro-audio"
            }
          }
        }
      ]
    '';

    "wireplumber/wireplumber.conf.d/52-gamedac-stable.conf".text = ''
      monitor.alsa.rules = [
        {
          matches = [
            {
              node.name = "~alsa_output.usb-SteelSeries_SteelSeries_GameDAC"
            }
          ]
          actions = {
            update-props = {
              session.suspend-timeout-seconds = 0
            }
          }
        }
      ]
    '';
  };
}
