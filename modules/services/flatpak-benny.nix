# Flatpak-Infrastruktur + Bazaar-App-Store (benny)
# - Bazaar = natives nixpkgs-Package
# - Flathub-Remote deklarativ
# - systemd-Timer aktualisiert die Flatpak-Apps automatisch
{ config, pkgs, lib, ... }:

{
  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    bazaar
  ];

  system.activationScripts.flatpak-remotes = lib.stringAfter [ "var" ] ''
    ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo || true
    ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo || true
  '';

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
      OnCalendar = "Mon,Fri 00:00";
      Persistent = true;
    };
  };
}
