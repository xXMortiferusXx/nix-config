# Minimaler Test-Host fuer Installer-Testing (QEMU-VM)
# Kein Desktop, keine Games — nur Basis-NixOS + SSH + NetworkManager.
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking.hostName = "test";

  # Flake-Support
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # NetworkManager (wie nex/styx)
  networking.networkmanager.enable = true;

  # SSH fuer Remote-Zugriff aus der Host-VM
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # Test-User
  users.users.test = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "test";
  };

  # sudo ohne Passwort ( fuer Installer-Test)
  security.sudo.wheelNeedsPassword = false;

  # Bootloader (systemd-boot wie nex/styx)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Basis-Pakete
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    parted
    gptfdisk
  ];

  system.stateVersion = "26.05";
}
