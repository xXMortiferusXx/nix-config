{ config, pkgs, inputs, ... }:
{
  users.groups.greeter = { };

  users.users.mortiferus = {
    isNormalUser = true;
    description = "Mortiferus";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "scanner" "lp" "openrazer" "gamemode" "greeter" ];
    shell = pkgs.fish;

    packages = with pkgs; [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      vulkan-tools
    ];
  };
}
