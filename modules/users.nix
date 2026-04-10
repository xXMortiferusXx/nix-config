{ config, pkgs, inputs, ... }:
{
  users.users.mortiferus = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "scanner" "lp" ];
    shell = pkgs.fish;
    packages = with pkgs; [
      # Browser
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      
      # Gaming & Launcher
      cartridges
      goverlay

      # Kommunikation & Office
      vesktop
      bitwarden-desktop
      libreoffice
      hunspellDicts.de_DE
      hyphenDicts.de-de

      # Medien & Grafik
      gimp
      loupe
      naps2

      # PDF-Sektion (MuPDF Fix)
      zathura
      zathuraPkgs.zathura_pdf_mupdf

      # System-Tools & Utilities
      jq
      yazi
      btop
      nautilus
      brightnessctl
      jamesdsp
      kdePackages.qt6ct
      libsForQt5.qt5ct

      # Optik & Design
      adwaita-icon-theme
      bibata-cursors
    ];
  };

  services.printing.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
}
