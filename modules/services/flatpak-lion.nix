# Flatpak-Infrastruktur + Bazaar-App-Store (nur für lion-pc)
# - Bazaar = natives nixpkgs-Package (wird per nixos-rebuild mitgeupdatet)
# - lion installiert eigenständig via Bazaar seine Apps (Roblox = Sober u.a.)
# - Flathub-Remote deklarativ hinzufügen
# - systemd-Timer aktualisiert die Flatpak-Apps automatisch
# - Polkit-Regel (modules/desktop/polkit.nix) erlaubt wheel-Installation passwordlos
{ config, pkgs, lib, ... }:

{
  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    bazaar
  ];

  # Flathub-Remote deklarativ registrieren (idempotent)
  system.activationScripts.flatpak-remotes = lib.stringAfter [ "var" ] ''
    ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo || true
    ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo || true
  '';

  # Flatpak-Apps aktualisieren sich NICHT von alleine → systemd-Timer
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
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  # Bazaar ist ein Flathub-Frontend: zeigt das GANZE Flathub (kein Altersfilter)
}