{ config, lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  services.udisks2.enable = true;

  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };

}
