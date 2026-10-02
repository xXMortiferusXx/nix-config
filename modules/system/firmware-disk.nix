# Firmware-Updates (fwupd/LVFS) + SSD-/HDD-Monitoring (smartd/smartctl)
# Für Desktop-Hosts, die nicht laptop-common.nix importieren.
{ pkgs, ... }:

{
  services.fwupd.enable = true;

  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.wall.enable = true;
  };

  environment.systemPackages = [ pkgs.smartmontools ];
}
