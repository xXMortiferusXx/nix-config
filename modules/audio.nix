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
  };
  services.pipewire.extraConfig.pipewire."99-lowlatency" = {
    "context.properties" = {
      # CachyOS-typische Latenz-Optimierung
      "default.clock.rate" = 48000;
      "default.clock.quantum" = 1024;
      "default.clock.min-quantum" = 32;
      "default.clock.max-quantum" = 2048;
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
