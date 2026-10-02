# Host: benny
# Intel CPU (i5-3xxx, Ivy Bridge) + Intel-Onboard-Grafik (HD 4000).
# Die defekte AMD Radeon R9 280 wurde ausgebaut -> kein GPU-Sonderfall mehr.
{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./disk-config.nix
      ../../modules/system/common.nix
      ../../modules/system/boot-benny.nix
      ../../modules/system/environment-benny.nix
      ../../modules/system/firmware-disk.nix
      ../../modules/hardware/intel-ivy.nix
      ../../modules/hardware/power-benny.nix
      ../../modules/programs/gaming/benny.nix
      ../../modules/services/flatpak-benny.nix
      ../../modules/users/benny.nix
      ../../modules/home/benny
      ./config-mounts.nix
    ];

  networking.hostName = "benny";

  # Arctis Sound Manager (SteelSeries GG/Sonar-Ersatz) — EQ/ChatMix/Virtual Surround.
  # Modul kommt aus dem Flake-Input arctis-sound-manager (siehe flake.nix).
  services.arctis-sound-manager.enable = true;

  # ASM-Tray-GUI (asm-gui --systray) registriert sich einmalig als SNI-Item.
  # Noctalia stellt den StatusNotifierWatcher aber erst nach dem Login bereit ->
  # gleicher Race wie bei Discord/Steam (waitForTray). Deshalb:
  #   1. vor dem Start auf den Noctalia-Tray-Watcher warten (ExecStartPre)
  #   2. an noctalia.service koppeln, damit ein Noctalia-Neustart (z. B. durch
  #      nix-sync) den Tray automatisch neu registriert (PartOf).
  systemd.user.services."app-ArctisManager" = {
    after = [ "noctalia.service" ];
    partOf = [ "noctalia.service" ];
    serviceConfig = {
      ExecStartPre = [
        (pkgs.writeShellScript "wait-for-tray" ''
          until ${pkgs.systemd}/bin/busctl --user get-property \
            org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
            org.kde.StatusNotifierWatcher IsStatusNotifierHostRegistered \
            2>/dev/null | ${pkgs.gnugrep}/bin/grep -q 'b true'; do
            ${pkgs.coreutils}/bin/sleep 0.3
          done
        '')
      ];
      # waitForTray wartet auf Noctalia; Standard-90s reichen beim langsamen
      # iGPU-Login nicht immer -> großzügiger Start-Timeout.
      TimeoutStartSec = "5min";
    };
  };

  hardware.bluetooth.enable = true;

  # IRQ-Balancing: IRQs gleichmäßig über die CPU-Kerne verteilen.
  services.irqbalance.enable = true;

  # DDC/CI (ddcutil): i2c-dev Kernel-Modul + i2c-Gruppe + Geräte-Rechte
  boot.kernelModules = [ "i2c-dev" ];
  users.groups.i2c = {};
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  # SSH deaktiviert: benny steht nicht im LAN von nex (kein Fernzugriff nötig).

  # Sicherheit: sudo-Passwort nötig (Override der common-Vorgabe aus security.nix)
  security.sudo.wheelNeedsPassword = lib.mkForce true;

  # Greeter-Sync (Wallpaper/Farben) passwortlos für den Haupt-User
  services.displayManager.noctalia-greeter.passwordlessSyncUsers = [ "benny" ];

  system.stateVersion = "26.05";
}
