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

    extraConfig.pipewire."99-lowlatency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 512;      # Deine bewährte Latenz für die Ortung
        "default.clock.min-quantum" = 128;   # Ein kleiner Sicherheitsanker für CPU-Stress
        "default.clock.max-quantum" = 2048;
      };
      
      # Das ist der entscheidende Teil für die Prio:
      "context.modules" = [
        {
          name = "libpipewire-module-rt";
          args = {
            "nice.level" = -15;
            "rt.prio" = 88;
          };
          flags = [ "ifexists" "nofail" ];
        }
      ];
    };
  };
  
  environment.variables.LADSPA_PATH = "/run/current-system/sw/lib/ladspa";

  environment.systemPackages = with pkgs; [ 
    pavucontrol 
    qpwgraph 
    ladspa-sdk
    ladspaPlugins
    alsa-utils
  ];
}
