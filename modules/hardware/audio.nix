{ config, pkgs, lib, ... }:

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
}
