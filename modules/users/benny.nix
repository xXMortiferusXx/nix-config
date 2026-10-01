# Benutzer benny
# Groups: networkmanager, wheel, video, audio, greeter
{ config, pkgs, inputs, ... }:
{
  users.users.benny = {
    isNormalUser = true;
    description = "Benny";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "greeter" "i2c" ];
    shell = pkgs.fish;

    packages = with pkgs; [
      firefox
    ];
  };
}
