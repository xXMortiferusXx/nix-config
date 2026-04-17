{ config, pkgs, inputs, ... }:
{
  users.users.mortiferus = {
    isNormalUser = true;
    description = "Mortiferus";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "scanner" "lp" ];
    shell = pkgs.fish;
    packages = with pkgs; [
      #3d Printing
      (makeDesktopItem {
        name = "ideamaker";
        desktopName = "ideaMaker";
        exec = "env QT_QPA_PLATFORM=xcb LD_LIBRARY_PATH=\"\" /home/mortiferus/Apps/ideaMaker.AppImage";
        icon = "/home/mortiferus/Apps/ideamaker.png"; # Hier jetzt den Pfad zum Bild rein
        comment = "Raise3D Slicing Software";
        categories = [ "Graphics" "3DGraphics" ];
        terminal = false;
        type = "Application";
      })
      prusa-slicer
      orca-slicer
      ############
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
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      adwaita-icon-theme
      bibata-cursors
      qt6Packages.qt6ct
      libsForQt5.qt5ct
      #wireplumber 
      brightnessctl
      # Dokumente & Bilder
       # PDF-Sektion (MuPDF Fix)
      zathura
      zathuraPkgs.zathura_pdf_mupdf
      loupe 
      gimp
      #Scanner Software
      naps2
      kdePackages.skanpage
    ];
  };

  # DIESER TEIL HAT GERADE GEFEHLT:
  # ──────────────────────────────────────────────────
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
  # ──────────────────────────────────────────────────

  services.gvfs.enable = true; 
  services.udisks2.enable = true;
  programs.fish.enable = true;
}
