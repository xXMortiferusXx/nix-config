{ config, pkgs, inputs, ... }:
{
  users.groups.greeter = { };

  users.users.mortiferus = {
    isNormalUser = true;
    description = "Mortiferus";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "scanner" "lp" "openrazer" "gamemode" "greeter" ];
    shell = pkgs.fish;

    packages = with pkgs; [
      # ideaMaker Wrapper
      (makeDesktopItem {
        name = "ideamaker";
        desktopName = "ideaMaker";
        exec = "env QT_QPA_PLATFORM=xcb /home/mortiferus/Apps/ideaMaker.AppImage";
        icon = "/home/mortiferus/Apps/ideamaker.png";
        comment = "Raise3D Slicing Software";
        categories = [ "Graphics" ];
        terminal = false;
        type = "Application";
      })

      # Browser & Tools
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

      # OpenGL/Vulkan Test-Tools
      vulkan-tools    # vulkaninfo

    ];
  };
}
