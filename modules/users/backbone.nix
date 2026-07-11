# Benutzer backbone (styx – Office-Laptop)
# Groups: networkmanager, wheel, video, audio, greeter
{ config, pkgs, inputs, ... }:
{
  users.users.backbone = {
    isNormalUser = true;
    description = "Backbone Administrator";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "greeter" ];
    shell = pkgs.fish;

    packages = with pkgs; [
      tmux
      # Browser (Flake-Integration) für Styx
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
