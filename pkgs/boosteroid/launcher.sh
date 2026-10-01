#!/bin/sh
# Boosteroid (Qt-Client) schreibt bstr_client.log und bstr_settings.ini NEBEN
# die Binary. Der Nix-Store ist read-only -> Binary einmalig in ein
# beschreibbares Verzeichnis kopieren und von dort starten.
set -e

APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/boosteroid"
mkdir -p "$APP_DIR"
DST="$APP_DIR/Boosteroid"
MARKER="$APP_DIR/.source-path"

if [ ! -e "$DST" ] || [ "$(cat "$MARKER" 2>/dev/null)" != "$BOOSTEROID_BIN" ]; then
  cp -f "$BOOSTEROID_BIN" "$DST.tmp"
  chmod +x "$DST.tmp"
  mv -f "$DST.tmp" "$DST"
  printf '%s\n' "$BOOSTEROID_BIN" > "$MARKER"
fi

exec "$DST" "$@"
