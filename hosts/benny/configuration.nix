# Host: benny
# Intel CPU (i5-3xxx, Ivy Bridge) + Intel-Onboard-Grafik (HD 4000).
# Die defekte AMD Radeon R9 280 wurde ausgebaut -> kein GPU-Sonderfall mehr.
{ config, pkgs, lib, inputs, ... }:

let
  # GameDAC-Knacken/Aussetzer-Fix (aus nex-Historie, Commit 9235fa9):
  # ASM-Filter-Ketten mit "node.pause-on-idle = false" erzeugen, damit die
  # Sonar-Convolution beim Stream-Neustart nicht in "idle" faellt und ihren
  # Zustand behaelt (kein Transient/Knacken am Liedanfang). Patch aufs
  # Upstream-Paket, damit er jede ASM-Regeneration uebersteht. Nur Output-
  # Ketten, die Micro-Input-Kette bleibt unangetastet (sonst bricht das Mic).
  arctis-sound-manager = inputs.arctis-sound-manager.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      ${pkgs.python3}/bin/python3 ${../../scripts/asm-pause-on-idle.py} src/arctis_sound_manager/sonar_to_pipewire.py
    '';
  });
in
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
      ../../modules/hardware/audio-gamedac.nix
      ../../modules/programs/gaming/benny.nix
      ../../modules/services/flatpak-benny.nix
      ../../modules/users/benny.nix
      ../../modules/home/benny
      ./config-mounts.nix
    ];

  networking.hostName = "benny";

  # Arctis Sound Manager (SteelSeries GG/Sonar-Ersatz) — EQ/ChatMix/Virtual Surround.
  # Modul kommt aus dem Flake-Input arctis-sound-manager (siehe flake.nix).
  # package-Override: pause-on-idle-Patch gegen Knacken/Aussetzer (siehe let-Block).
  services.arctis-sound-manager.enable = true;
  services.arctis-sound-manager.package = arctis-sound-manager;

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

  # Greeter-Sync (Wallpaper/Farben) passwortlos für den Haupt-User
  services.displayManager.noctalia-greeter.passwordlessSyncUsers = [ "benny" ];

  system.stateVersion = "26.05";
}
