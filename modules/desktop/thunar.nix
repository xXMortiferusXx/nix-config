# Thunar Dateimanager mit Archiv-Entpack-Actions
# Installiert Thunar + Archive-Plugin und definiert Custom Actions
# für "Hier entpacken" und "In Ordner entpacken" als Untermenü
{ config, pkgs, ... }:

let
  # Helper-Script: erkennt Archivformat und entpackt mit dem passenden Tool
  thunar-extract = pkgs.writeShellScriptBin "thunar-extract" ''
    set -euo pipefail
    FILE="$1"
    DEST_DIR="$2"
    MODE="$3"  # "here" oder "tofolder"

    FILENAME=$(basename "$FILE")
    BASENAME="''${FILENAME%%.*}"

    if [ "$MODE" = "tofolder" ]; then
      OUTDIR="$DEST_DIR/$BASENAME"
      mkdir -p "$OUTDIR"
    else
      OUTDIR="$DEST_DIR"
    fi

    case "$FILE" in
      *.zip)
        ${pkgs.unzip}/bin/unzip -q -o "$FILE" -d "$OUTDIR"
        ;;
      *.tar.gz|*.tgz)
        ${pkgs.gnutar}/bin/tar -xzf "$FILE" -C "$OUTDIR"
        ;;
      *.tar.bz2|*.tbz2)
        ${pkgs.gnutar}/bin/tar -xjf "$FILE" -C "$OUTDIR"
        ;;
      *.tar.xz|*.txz)
        ${pkgs.gnutar}/bin/tar -xJf "$FILE" -C "$OUTDIR"
        ;;
      *.tar)
        ${pkgs.gnutar}/bin/tar -xf "$FILE" -C "$OUTDIR"
        ;;
      *.7z)
        ${pkgs.p7zip}/bin/7z x "$FILE" -o"$OUTDIR" -y
        ;;
      *.rar)
        ${pkgs.unrar}/bin/unrar x -o+ "$FILE" "$OUTDIR/"
        ;;
      *)
        echo "Unbekanntes Archivformat: $FILE" >&2
        exit 1
        ;;
    esac
  '';

  # Gemeinsame Dateimuster für alle Archivformate
  archivePatterns = "*.zip;*.tar.gz;*.tgz;*.tar.bz2;*.tbz2;*.tar.xz;*.txz;*.tar;*.7z;*.rar";
in

{
  # Thunar aktivieren (kein Archive-Plugin – Custom Actions reichen)
  programs.thunar = {
    enable = true;
  };

  # Extraktions-Tools + thunar-extract Script systemweit bereitstellen
  environment.systemPackages = [
    thunar-extract
    pkgs.unzip
    pkgs.gnutar
    pkgs.p7zip
    pkgs.unrar
  ];
}
