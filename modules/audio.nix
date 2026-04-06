{ config, pkgs, ... }:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  # Helvum gelöscht, qpwgraph bleibt als Alternative
  environment.systemPackages = with pkgs; [ pavucontrol qpwgraph ]; 
}
