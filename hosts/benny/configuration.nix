# Host: benny
# Intel CPU (i5-3xxx, Ivy Bridge) + Intel-Onboard-Grafik (HD 2500).
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
      ../../modules/hardware/xbox-controller.nix
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

  # Realtek r8169 (RTL8168f, 0000:03:00.0): nach S3-Resume kommt der Link oft
  # nicht zurueck. Bekannter Workaround: Modul beim Resume neu laden (setzt den
  # Controller komplett zurueck; reines ip-link-down/up reicht oft nicht).
  environment.systemPackages = [ pkgs.ethtool ];
  powerManagement.resumeCommands = ''
    ${pkgs.ethtool}/bin/ethtool -s enp3s0 wol d || true
    ${pkgs.kmod}/bin/modprobe -r r8169 || true
    ${pkgs.kmod}/bin/modprobe r8169 || true
    ${pkgs.iproute2}/bin/ip link set enp3s0 up || true
    ${pkgs.ethtool}/bin/ethtool -s enp3s0 autoneg on || true
  '';

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

  # sched_ext: latenzorientierter Scheduler (Frame-Pacing) fuer Cloud-Gaming.
  # Beim Switch wird der systemd-Service direkt gestartet -> kein Reboot noetig.
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  # DDC/CI (ddcutil): i2c-dev Kernel-Modul + i2c-Gruppe + Geräte-Rechte
  boot.kernelModules = [ "i2c-dev" ];
  users.groups.i2c = {};
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  # SSH fuer Fernzugriff von aussen (DynDNS benberlin29.ddnss.de); nur Keys,
  # kein root, Port 22 im Firewall geoeffnet. Portweiterleitung macht der Router.
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  users.users.benny.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6UHVcDl2byF1+1SYIpM3V0oldx/541PX9a9bX+smBr mortiferus@nex"
  ];

  # Greeter-Sync (Wallpaper/Farben) passwortlos für den Haupt-User
  services.displayManager.noctalia-greeter.passwordlessSyncUsers = [ "benny" ];

  system.stateVersion = "26.05";
}
