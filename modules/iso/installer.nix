# Minimal-Live-ISO für Neuinstallationen (USB) und QEMU-Tests.
#
# Stellt den Befehl `install-nixos` bereit: holt die AKTUELLE install.sh aus
# dem Repo (Branch main) und startet sie. Ist GitHub nicht erreichbar, wird
# die beim Bauen eingebettete Fassung benutzt - das ISO bleibt also auch ohne
# Netz zum Repo brauchbar (installiert wird ohnehin nur mit Netz).
#
# Basis: nixpkgs installation-cd-minimal (Autologin als `nixos`, wheel,
# passwortloses sudo). `install-nixos` startet install.sh GENAU WIE VON HAND
# (`./install.sh`) als angemeldeten User - das Skript macht seine root-Aufrufe
# selbst per sudo und bricht ab, wenn es als root laeuft.
{ config, pkgs, lib, ... }:

let
  installUrl = "https://raw.githubusercontent.com/xXMortiferusXx/nix-config/main/install.sh";

  # Wird beim Bauen aus dem Repo mitgenommen: Fallback ohne GitHub-Zugriff.
  installBaked = ../../install.sh;

  installNixos = pkgs.writeShellScriptBin "install-nixos" ''
    set -u
    url="''${INSTALL_URL:-${installUrl}}"
    tmp=$(${pkgs.coreutils}/bin/mktemp)
    trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT

    echo "== NixOS-Installer =="
    if ${pkgs.curl}/bin/curl -fsSL --max-time 30 "$url" -o "$tmp"; then
      echo "install.sh geladen von: $url"
    else
      echo "GitHub nicht erreichbar - nutze die im ISO eingebettete install.sh."
      ${pkgs.coreutils}/bin/cp ${installBaked} "$tmp"
    fi

    echo "SHA256: $(${pkgs.coreutils}/bin/sha256sum "$tmp" | ${pkgs.coreutils}/bin/cut -d' ' -f1)"
    echo

    # install.sh macht seine root-Aufrufe SELBST per sudo (78 Stellen) und
    # bricht bewusst ab, wenn es als root gestartet wird:
    #   "Bitte das Skript NICHT als root ausführen (sudo wird automatisch verwendet)."
    # Also hier genau wie von Hand `./install.sh` - ohne sudo, als der
    # angemeldete User. Ein vorangestelltes sudo würde das Skript sofort
    # abbrechen lassen.
    exec ${pkgs.bash}/bin/bash "$tmp" "$@"
  '';
in
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Deutsche Tastatur in der Live-Konsole (Login, nmtui, install.sh).
  console.keyMap = lib.mkForce "de-latin1";

  # Sprechender Dateiname: nixos-install-<label>-<system>.iso
  image.baseName = lib.mkForce
    "nixos-install-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    parted
    installNixos
  ];

  # Statt der Standard-Hilfe direkt die beiden noetigen Schritte zeigen.
  services.getty.helpLine = lib.mkForce ''
    WLAN einrichten:        nmtui
    Installation starten:   install-nixos

    install-nixos holt die aktuelle install.sh aus dem Repo (Fallback: die im
    ISO eingebettete Fassung) und zeigt vor dem Start Version und SHA256 an.
    Netz ist Pflicht - ohne Verbindung laeuft die Installation nicht.
  '';
}
