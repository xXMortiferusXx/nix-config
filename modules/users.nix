{ config, pkgs, inputs, ... }:
{
  users.users.mortiferus = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "scanner" "lp" ];
    shell = pkgs.fish;
    packages = with pkgs; [
      bitwarden-desktop
      cartridges
      kitty
      nautilus
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      adwaita-icon-theme
      bibata-cursors
      qt6Packages.qt6ct
      libsForQt5.qt5ct
      wireplumber 
      brightnessctl
      # Dokumente & Bilder
      zathura
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
