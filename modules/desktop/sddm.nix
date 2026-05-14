{ config, pkgs, lib, ... }:

{
  services.xserver.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    #package = pkgs.kdePackages.sddm;
    theme = "ltmnight";
    setupScript = ''
      ${pkgs.xrdb}/bin/xrdb -merge <<EOF
      Xcursor.theme: Bibata-Modern-Ice
      Xcursor.size: 24
      EOF
    '';
    extraPackages = with pkgs; [
      kdePackages.qtmultimedia
      kdePackages.qtsvg
      kdePackages.qt5compat
      kdePackages.qtvirtualkeyboard
      bibata-cursors
    ];
  };

  systemd.services.display-manager.environment = {
    LANG = "de_DE.UTF-8";
    LC_ALL = "de_DE.UTF-8";
  };

  environment.systemPackages = [
    (pkgs.callPackage ./sddm-themes/ltmnight.nix {})
  ];
}
