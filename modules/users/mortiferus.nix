# Benutzer mortiferus (nex – Gaming-Laptop)
# Groups: networkmanager, wheel, video, audio, input, greeter
{ config, pkgs, inputs, ... }:
{
  users.groups.greeter = { };

  users.users.mortiferus = {
    isNormalUser = true;
    description = "Mortiferus";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "scanner" "lp" "greeter" ];
    shell = pkgs.fish;

    packages = with pkgs; [
      firefox
    ];
  };
}
