{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./disk-config.nix
      ../../modules/system/common.nix
      ../../modules/system/boot-lion.nix
      ../../modules/system/environment-lion.nix
      ../../modules/hardware/amdgpu.nix
      ../../modules/hardware/power-lion.nix
      ../../modules/programs/gaming/lion.nix
      ../../modules/programs/tools.nix
      ../../modules/services/flatpak-lion.nix
      ../../modules/users/lion.nix
      ../../modules/home/lion
      ./config-mounts.nix
    ];

  networking.hostName = "lion-pc";

  # DDC/CI (ddcutil): i2c-dev Kernel-Modul + i2c-Gruppe + Geräte-Rechte
  boot.kernelModules = [ "i2c-dev" ];
  users.groups.i2c = {};
  services.udev.extraRules = ''
    # /dev/i2c-* für die i2c-Gruppe freigeben (ddcutil braucht rw-Zugriff)
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  # SSH: Lokaler Zugriff von nex (Key-basiert, kein Passwort)
  services.openssh = {
    enable = true;
    openFirewall = false;  # Manuelles Firewall-Setup unten
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  users.users.lion.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6UHVcDl2byF1+1SYIpM3V0oldx/541PX9a9bX+smBr mortiferus@nex"
  ];

  # Firewall: SSH nur aus LAN (192.168.50.0/24), extern blockiert
  networking.firewall.extraCommands = ''
    # SSH aus LAN erlauben
    iptables -A nixos-fw -s 192.168.50.0/24 -p tcp --dport 22 -j nixos-fw-accept
  '';

  # Sicherheit: sudo-Passwort nötig (Override der common-Vorgabe aus security.nix: false).
  # Bazaar/Flatpak bleibt via Polkit-Regel passwordlos; eine bösartige Flatpak-App
  # kann damit nicht über passwordloses sudo zu Root eskalieren.
  security.sudo.wheelNeedsPassword = lib.mkForce true;

  system.stateVersion = "26.05";
}