{ config, pkgs, ... }:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    # 1. PLUGIN PFADE SETZEN
    extraConfig.pipewire."99-ladspa-path" = {
      "context.properties" = {
        "spa.plugin.dir" = "${pkgs.pipewire}/lib/spa-0.2";
      };
    };

    # 2. DER SURROUND FILTER (HRTF)
    extraConfig.pipewire."99-surround-filter" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "SOFA Virtual Surround";
            "node.name" = "SurroundFilter";
            "filter.graph" = {
              nodes = [
                {
                  type = "builtin";
                  name = "convolver";
                  label = "convolver";
                  config = {
                    # WICHTIG: ./ wenn die wav im selben Ordner wie audio.nix liegt
                    # ../ wenn sie einen Ordner drüber (in /etc/nixos/) liegt
                    filename = "${../hrir_stereo_strip_48k.wav}"; 
                    variant = "hrir";
                  };
                }
              ];
            };
            "capture.props" = {
              "node.name" = "SurroundInput";
              "media.class" = "Audio/Sink";
              "audio.channels" = 8;
              "audio.position" = [ "FL" "FR" "FC" "LFE" "RL" "RR" "SL" "SR" ];
            };
            "playback.props" = {
              "node.name" = "SurroundOutput";
              "media.class" = "Audio/Source";
              "audio.channels" = 2;
              "audio.position" = [ "FL" "FR" ];
              "target.object" = "HeadsetSink"; 
            };
          };
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [ 
    pavucontrol 
    qpwgraph 
    ladspa-sdk
    ladspaPlugins
    alsa-utils
  ];

  environment.variables.LADSPA_PATH = "/run/current-system/sw/lib/ladspa";
}
