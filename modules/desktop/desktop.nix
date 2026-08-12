{ config, pkgs, ... }:

{
  services.systembus-notify.enable = true;

  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.xfconf.enable = true;
  services.tumbler.enable = true;
  programs.xwayland.enable = true;

  environment.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    XCURSOR_PATH = [
      "$HOME/.icons"
      "$HOME/.local/share/icons"
      "/run/current-system/sw/share/icons"
    ];
  };

  environment.systemPackages = with pkgs; [
    bibata-cursors
    cifs-utils
    samba
    gvfs
  ];
}
