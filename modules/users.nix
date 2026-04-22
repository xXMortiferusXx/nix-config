{ config, pkgs, inputs, ... }:
{
  users.users.mortiferus = {
    isNormalUser = true;
    description = "Mortiferus";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "scanner" "lp" ];
    shell = pkgs.fish;

    packages = with pkgs; [
      # 3D Printing
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
      prusa-slicer
      orca-slicer
      
      # Icons
      tela-circle-icon-theme
      papirus-icon-theme
      adwaita-icon-theme
      bibata-cursors
      
      # Tools
      helix
      jq
      libreoffice
      hunspellDicts.de_DE
      hyphenDicts.de-de
      yazi
      btop
      vesktop
      bitwarden-desktop
      cartridges
      kitty
      nautilus
      brightnessctl
      
      # KI
      aider-chat

      # Browser & System
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      qt6Packages.qt6ct
      libsForQt5.qt5ct
      
      # Dokumente & Bilder
      zathura
      loupe 
      gimp
      naps2
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
