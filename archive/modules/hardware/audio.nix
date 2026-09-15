{ config, pkgs, lib, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Basis-PipeWire für alle Hosts. GameDAC-spezifisches (ALSA-Profil, Low-Latency)
  # liegt in modules/hardware/gamedac.nix und wird nur von nex importiert.

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
