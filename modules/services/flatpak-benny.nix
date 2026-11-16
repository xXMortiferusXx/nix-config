# Flatpak-Infrastruktur + Bazaar-App-Store (benny)
# Flathub-Remote deklarativ + systemd-Timer für Auto-Updates.
{ config, pkgs, lib, ... }:

let
  # Flathub-Remote aus einer mitgelieferten Konfigurationsdatei registrieren —
  # bewusst OHNE Netzwerkzugriff.
  #
  # Warum: `flatpak remote-add … https://…` lädt die .flatpakrepo-Datei erst
  # zur Laufzeit. Die NixOS-Aktivierung läuft aber (a) in der initrd, bevor es
  # DNS gibt, und (b) beim Installieren im nixos-enter-Chroot, wo
  # /etc/resolv.conf auf den dort nicht laufenden systemd-resolved zeigt. In
  # beiden Fällen brach der Aufruf mit "Could not resolve hostname" ab, obwohl
  # Netzwerk vorhanden war. Eine lokale Datei funktioniert immer, auch offline.
  #
  # Inhalt = unveränderte Kopie von
  #   https://dl.flathub.org/repo/flathub.flatpakrepo
  # (sha256 3371dd250e61d9e1633630073fefda153cd4426f72f4afa0c3373ae2e8fea03a).
  # Bei Änderungen upstream (z. B. Schlüsselrotation) neu ziehen:
  #   curl -sSL https://dl.flathub.org/repo/flathub.flatpakrepo \
  #     -o modules/services/flathub.flatpakrepo
  flathubRepo = ./flathub.flatpakrepo;
in
{
  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    bazaar
  ];

  system.activationScripts.flatpak-remotes = lib.stringAfter [ "var" ] ''
    # Nur die System-Installation: dieses Skript läuft als root, ein `--user`
    # landet in /root/.local/share/flatpak und ist für Desktop-User nutzlos.
    # Bazaar installiert systemweit (erlaubt durch die Polkit-Regel in
    # modules/desktop/polkit.nix).
    #
    # Ausgabe wird eingefangen: beim ersten Anlegen warnt flatpak, dass es die
    # Metadaten nicht aktualisieren kann - das erledigt der Update-Timer.
    # Echte Fehler werden weiterhin sichtbar gemeldet.
    if ! flatpak_add_out=$(${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists \
          --system flathub ${flathubRepo} 2>&1); then
      echo "WARNUNG: Flathub-Remote konnte nicht registriert werden: $flatpak_add_out" >&2
    fi
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
