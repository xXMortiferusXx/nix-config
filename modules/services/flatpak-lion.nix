# Flatpak-Infrastruktur + Bazaar-App-Store (nur für lion-pc)
# Flathub-Remote deklarativ; Updates macht Bazaar selbst (Auto-Update).
# Polkit-Regel (modules/desktop/polkit.nix) erlaubt wheel-Installation passwordlos.
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

  # GPG-Schlüssel aus derselben Datei (steht dort base64-kodiert in `GPGKey=`)
  # als binäre Keyring-Datei. Wird beim Bauen erzeugt, nicht zur Laufzeit.
  flathubKey = pkgs.runCommand "flathub-gpg-key" { } ''
    ${pkgs.gnugrep}/bin/grep -m1 '^GPGKey=' ${flathubRepo} \
      | ${pkgs.coreutils}/bin/cut -d= -f2- \
      | ${pkgs.coreutils}/bin/base64 -d > $out
  '';
in
{
  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    bazaar
  ];

  # Flathub-Remote deklarativ registrieren
  system.activationScripts.flatpak-remotes = lib.stringAfter [ "var" ] ''
    # Nur die System-Installation: dieses Skript läuft als root, ein `--user`
    # landet in /root/.local/share/flatpak und ist für Desktop-User nutzlos.
    # Bazaar installiert systemweit (erlaubt durch die Polkit-Regel in
    # modules/desktop/polkit.nix).
    #
    # Ausgabe wird eingefangen: beim ersten Anlegen warnt flatpak, dass es die
    # Metadaten nicht aktualisieren kann - das erledigt Bazaar selbst.
    # Echte Fehler werden weiterhin sichtbar gemeldet.
    if ! flatpak_add_out=$(${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists \
          --system flathub ${flathubRepo} 2>&1); then
      echo "WARNUNG: Flathub-Remote konnte nicht registriert werden: $flatpak_add_out" >&2
    fi

    # Schlüssel bei jeder Aktivierung nachziehen: `remote-add --if-not-exists`
    # ist bei bestehendem Remote ein No-Op - ein geänderter Schlüssel käme sonst
    # nie in den Keyring. Der Import ist idempotent und braucht kein Netz.
    if ! flatpak_key_out=$(${pkgs.flatpak}/bin/flatpak remote-modify --system \
          --gpg-import=${flathubKey} flathub 2>&1); then
      echo "WARNUNG: Flathub-GPG-Schlüssel konnte nicht importiert werden: $flatpak_key_out" >&2
    fi
  '';

  # Trust-Anker aktuell halten: Flatpak kann einen rotierten Schlüssel NICHT
  # selbst nachladen - der Schlüssel prüft ja genau das, was nachgeladen wird
  # (sonst könnte ein kompromittierter Repo-Server einen neuen Schlüssel plus
  # Schad-Apps ausliefern). Also holen WIR die aktuelle .flatpakrepo über TLS
  # und importieren den Schlüssel additiv. Der beim Aktivieren importierte,
  # gepinnte Schlüssel bleibt als Fallback (offline, Erstinstallation).
  #
  # Ohne Netz passiert hier bewusst nichts (exit 0, keine Journal-Fehler).
  systemd.services.flatpak-key-refresh = {
    description = "Flathub-GPG-Schlüssel aktualisieren";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      tmpdir=$(${pkgs.coreutils}/bin/mktemp -d)
      trap '${pkgs.coreutils}/bin/rm -rf "$tmpdir"' EXIT

      if ! ${pkgs.curl}/bin/curl -fsL --max-time 30 \
           https://dl.flathub.org/repo/flathub.flatpakrepo \
           -o "$tmpdir/repo.flatpakrepo"; then
        exit 0
      fi

      ${pkgs.gnugrep}/bin/grep -m1 '^GPGKey=' "$tmpdir/repo.flatpakrepo" \
        | ${pkgs.coreutils}/bin/cut -d= -f2- \
        | ${pkgs.coreutils}/bin/base64 -d > "$tmpdir/flathub.gpg"

      if ! ${pkgs.coreutils}/bin/test -s "$tmpdir/flathub.gpg"; then
        echo "WARNUNG: kein GPGKey in flathub.flatpakrepo gefunden" >&2
        exit 0
      fi

      if ! refresh_out=$(${pkgs.flatpak}/bin/flatpak remote-modify --system \
           --gpg-import="$tmpdir/flathub.gpg" flathub 2>&1); then
        echo "WARNUNG: Flathub-Schlüssel konnte nicht aktualisiert werden: $refresh_out" >&2
      fi
    '';
  };

  systemd.timers.flatpak-key-refresh = {
    description = "Flathub-GPG-Schlüssel täglich prüfen";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1d";
      Persistent = true;
    };
  };

  # Updates macht Bazaar (Hersteller-Weg) - kein eigener root-Timer mehr.
  #
  # 1) `auto-update` ist im GSettings-Schema standardmäßig false, also
  #    systemweit vorbelegen. Der Wert gilt als Vorgabe und lässt sich im
  #    Bazaar-Fenster weiterhin pro User umstellen.
  programs.dconf.profiles.user.databases = [{
    settings."io/github/kolunmi/Bazaar" = {
      auto-update = true;
    };
  }];

  # 2) Der Daemon startet sonst nur auf D-Bus-Anfrage (Bazaar-Fenster oder
  #    GNOME-Suche) - dann gäbe es keine Hintergrund-Updates. Unit aus dem
  #    Bazaar-Paket, nur zusätzlich an die grafische Sitzung gehängt.
  #    Bazaar prüft danach täglich (mit zufälligem Stunden-Offset).
  systemd.user.services."io.github.kolunmi.Bazaar" = {
    description = "Bazaar Service";
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "dbus";
      BusName = "io.github.kolunmi.Bazaar";
      ExecStart = "${pkgs.bazaar}/bin/bazaar-daemon --no-window";
    };
  };
}
