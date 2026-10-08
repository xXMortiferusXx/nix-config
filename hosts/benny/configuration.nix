# Host: benny
# Intel CPU (i5-3xxx, Ivy Bridge) + Intel-Onboard-Grafik (HD 4000).
# Die defekte AMD Radeon R9 280 wurde ausgebaut -> kein GPU-Sonderfall mehr.
{ config, pkgs, lib, inputs, ... }:

let
  # GameDAC-Knacken-Fix: ASM-Ketten mit pause-on-idle=false patchen (nur Output, sonst bricht Mic).
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

  # FritzBox-Standard-Config (nicht am ASUS): DNS/Fallback auf 192.168.178.1.
  network.dnsServer = "192.168.178.1";

  # Arctis Sound Manager (Flake-Input) mit pause-on-idle-Patch (siehe let-Block).
  services.arctis-sound-manager.enable = true;
  services.arctis-sound-manager.package = arctis-sound-manager;

  # ASM-Tray wartet per ExecStartPre auf Noctalia-Tray und ist via PartOf an noctalia.service gekoppelt.
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
      # waitForTray braucht beim langsamen iGPU-Login mehr als die Standard-90s.
      TimeoutStartSec = "5min";
    };
  };

  hardware.bluetooth.enable = true;

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
