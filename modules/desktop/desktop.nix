{ config, pkgs, ... }:

{
  services.systembus-notify.enable = true;

  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.xfconf.enable = true;
  services.tumbler.enable = true;
  programs.xwayland.enable = true;

  environment.systemPackages = with pkgs; [
    cifs-utils
    samba
    gvfs
  ];
}
