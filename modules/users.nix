{ config, pkgs, inputs, ... }:
{
  users.users.mortiferus = {
    isNormalUser = true;
    description = "Mortiferus";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "scanner" "lp" "openrazer" ];
    shell = pkgs.fish;

    # Hier bleiben nur Pakete, die systemnah sind oder spezielle Wrapper benötigen
    packages = with pkgs; [
      # 3D Printing Wrapper
      (makeDesktopItem {
        name = "ideamaker";
        desktopName = "ideaMaker";
        exec = "env QT_QPA_PLATFORM=xcb LD_LIBRARY_PATH=\"\" /home/mortiferus/Apps/ideaMaker.AppImage";
        icon = "/home/mortiferus/Apps/ideamaker.png";
        comment = "Raise3D Slicing Software";
        categories = [ "Graphics" "3DGraphics" ];
        terminal = false;
        type = "Application";
      })
      
      # Browser & System-Tools (bleiben hier wegen Flake-Integration oder System-Relevanz)
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      qt6Packages.qt6ct
      libsForQt5.qt5ct
    ];
  };

  # System-Dienste
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;
  programs.fish.enable = true;
  security.sudo.wheelNeedsPassword = false;
}
