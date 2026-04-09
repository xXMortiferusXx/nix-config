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

  environment.systemPackages = with pkgs; [ 
    pavucontrol 
    qpwgraph 
    ladspa-sdk
    ladspaPlugins
    alsa-utils
  ];

  environment.variables.LADSPA_PATH = "/run/current-system/sw/lib/ladspa";
}
