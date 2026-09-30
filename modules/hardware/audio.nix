{ config, pkgs, lib, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Basis-PipeWire für alle Hosts. Spezifische Geräte-Configs (z. B. der
  # GC7 in audio-gc7.nix) werden pro Host ergänzt.

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
    alsa-utils
  ];
}
