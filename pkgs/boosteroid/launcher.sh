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

# Fuer bennys HD 4000 (i965): VA-API erzwingen und H.264-Codec anfordern
# (HD 4000 kann kein HEVC/AV1). -h264 gilt nur fuer die Stable-Version und
# wird von anderen Builds ignoriert. Zusaetzliche Argumente bleiben moeglich.
set -- -vaapi -h264 "$@"

# Waehrend des Streams Performance-Profil + CPU-Governor auf performance setzen,
# danach wiederherstellen. Intels ohne EPP (Ivy Bridge) reagieren nicht auf PPD,
# daher zusaetzlich der Governor.
prev_profile=""
if command -v powerprofilesctl >/dev/null 2>&1; then
  prev_profile=$(powerprofilesctl get 2>/dev/null || true)
  powerprofilesctl set performance >/dev/null 2>&1 || true
fi
prev_gov=""
for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  [ -e "$f" ] || continue
  prev_gov="$prev_gov $f:$(cat "$f" 2>/dev/null)"
  echo performance | sudo -n tee "$f" >/dev/null 2>&1 || true
done
restore() {
  if [ -n "$prev_profile" ]; then
    powerprofilesctl set "$prev_profile" >/dev/null 2>&1 || true
  fi
  for entry in $prev_gov; do
    f=${entry%:*}; v=${entry##*:}
    echo "$v" | sudo -n tee "$f" >/dev/null 2>&1 || true
  done
}
trap restore EXIT INT TERM HUP

exec "$DST" "$@"
