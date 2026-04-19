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
        "default.clock.quantum" = 1024;      # Ein sicherer Mittelwert (vorher 1024)
        "default.clock.min-quantum" = 64;   # Etwas entspannter (vorher 32)
        "default.clock.max-quantum" = 2048; # Genug Puffer für Hintergrundmusik
      };
    };
  };
  
  environment.variables.LADSPA_PATH = "/run/current-system/sw/lib/ladspa";

  environment.systemPackages = with pkgs; [ 
    pavucontrol 
    qpwgraph 
    ladspa-sdk
    ladspaPlugins
    alsa-utils
    # jamesdsp ist bereits in deiner users.nix, das reicht!
  ];
}
