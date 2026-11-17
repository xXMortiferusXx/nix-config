# Minimal-Live-ISO für Neuinstallationen (USB) und QEMU-Tests.
#
# Stellt den Befehl `install-nixos` bereit: holt die AKTUELLE install.sh aus
# dem Repo (Branch main) und startet sie. Ist GitHub nicht erreichbar, wird
# die beim Bauen eingebettete Fassung benutzt - das ISO bleibt also auch ohne
# Netz zum Repo brauchbar (installiert wird ohnehin nur mit Netz).
#
# Basis: nixpkgs installation-cd-minimal (Autologin als `nixos`, wheel,
# passwortloses sudo). `install-nixos` hebt sich per sudo selbst auf root,
# wenn es nicht schon als root läuft.
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

    # Live-ISO meldet als `nixos` an (wheel, passwortloses sudo) - das Skript
    # erwartet root, wie bei `curl ... | sudo bash`.
    if [ "$(${pkgs.coreutils}/bin/id -u)" -ne 0 ]; then
      exec ${pkgs.sudo}/bin/sudo -- ${pkgs.bash}/bin/bash "$tmp" "$@"
    fi
    exec ${pkgs.bash}/bin/bash "$tmp" "$@"
  '';
in
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

  # Statt der Standard-Hilfe direkt den Einstiegspunkt zeigen.
  services.getty.helpLine = lib.mkForce ''
    Installation starten:   install-nixos

    Der Befehl holt die aktuelle install.sh aus dem Repo (Fallback: die im ISO
    eingebettete Fassung) und zeigt vor dem Start Version und SHA256 an.
  '';
}
