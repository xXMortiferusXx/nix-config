# Flatpak-Infrastruktur + Bazaar-App-Store (nur für lion-pc)
# Flathub-Remote deklarativ + systemd-Timer für Auto-Updates.
# Polkit-Regel (modules/desktop/polkit.nix) erlaubt wheel-Installation passwordlos.
{ config, pkgs, lib, ... }:

{
  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    bazaar
  ];

  # Flathub-Remote deklarativ registrieren
  system.activationScripts.flatpak-remotes = lib.stringAfter [ "var" ] ''
    ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo || true
    ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo || true
  '';

  # Flatpak-Apps aktualisieren sich nicht von alleine -> systemd-Timer
  systemd.services.flatpak-update = {
    description = "Flatpak application updates";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.flatpak}/bin/flatpak update --noninteractive --assumeyes";
    };
  };

  systemd.timers.flatpak-update = {
    description = "Weekly Flatpak update";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # 2x die Woche (Mo+Fr), damit Roblox-Fixes zeitnah ankommen.
      OnCalendar = "Mon,Fri 00:00";
      Persistent = true;
    };
  };

  # Bazaar zeigt das ganze Flathub (kein Altersfilter).
}