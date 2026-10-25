#!/bin/sh
# Boosteroid (Qt-Client) schreibt bstr_client.log und bstr_settings.ini NEBEN
# die Binary. Der Nix-Store ist read-only -> Binary einmalig in ein
# beschreibbares Verzeichnis kopieren.
#
# Der Client legt selbst Desktop-Shortcuts an, die direkt auf
# $APP_DIR/Boosteroid zeigen. Damit diese Shortcuts Flags und Performance-
# Handling bekommen, ist $APP_DIR/Boosteroid ein Wrapper-Skript und die echte
# Binary liegt daneben als Boosteroid.bin.
set -e

APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/boosteroid"
mkdir -p "$APP_DIR"
BIN="$APP_DIR/Boosteroid.bin"
WRAP="$APP_DIR/Boosteroid"
MARKER="$APP_DIR/.source-path"

if [ ! -e "$BIN" ] || [ "$(cat "$MARKER" 2>/dev/null)" != "$BOOSTEROID_BIN" ]; then
  cp -f "$BOOSTEROID_BIN" "$BIN.tmp"
  chmod +x "$BIN.tmp"
  mv -f "$BIN.tmp" "$BIN"
  printf '%s\n' "$BOOSTEROID_BIN" > "$MARKER"
fi

cat > "$WRAP.tmp" <<'WRAPPER'
#!/bin/sh
# Wrapper fuer Boosteroid: VA-API-Flags + Performance, danach Wiederherstellung.
set -- -vaapi -h264 "$@"

# Natives Wayland bevorzugen (XWayland-Cursorgrab ist traege); Fallback xcb.
export QT_QPA_PLATFORM="wayland;xcb"

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

exec "$(dirname "$0")/Boosteroid.bin" "$@"
WRAPPER
chmod +x "$WRAP.tmp"
mv -f "$WRAP.tmp" "$WRAP"

exec "$WRAP" "$@"
