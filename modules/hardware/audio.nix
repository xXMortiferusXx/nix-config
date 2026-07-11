{ config, pkgs, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;

    extraConfig.pipewire."99-lowlatency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 64;
        "default.clock.max-quantum" = 2048;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
    qpwgraph
    ladspaPlugins
    alsa-utils
  ];
}
