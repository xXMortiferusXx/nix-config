#!/bin/sh
# Boosteroid (Qt-Client) schreibt bstr_client.log und bstr_settings.ini NEBEN
# die Binary. Der Nix-Store ist read-only -> Binary einmalig in ein
# beschreibbares Verzeichnis kopieren.
#
# Der Client legt selbst Desktop-Shortcuts an, die direkt auf
# $APP_DIR/Boosteroid zeigen. Damit diese Shortcuts Flags und Performance-
# Handling bekommen, ist $APP_DIR/Boosteroid ein Wrapper-Skript und die echte
# Binary liegt daneben als Boosteroid.bin.
#
# In-App-Update: Der Client entpackt upstream ein neues "Boosteroid" und
# kopiert es per "pkexec cp -a" genau auf den Wrapper. Das Ergebnis ist eine
# echte ELF-Datei (cp -a behaelt die Zeit aus dem Tar -> kein mtime-Vergleich).
# Sie wird hier uebernommen und bekommt Interpreter + RPATH der vom Nix-Paket
# gepatchten Binary, sonst startet sie auf NixOS nicht (Upstream erwartet
# /lib64/ld-linux-x86-64.so.2 und hat keinen RPATH).
set -e

PATCHELF="@PATCHELF@"

APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/boosteroid"
mkdir -p "$APP_DIR"
BIN="$APP_DIR/Boosteroid.bin"
WRAP="$APP_DIR/Boosteroid"
MARKER="$APP_DIR/.source-path"

is_elf() {
  [ -f "$1" ] || return 1
  [ "$(head -c 4 "$1" 2>/dev/null | od -An -tx1 | tr -d ' \n')" = "7f454c46" ]
}

install_store_bin() {
  cp -f "$BOOSTEROID_BIN" "$BIN.tmp"
  chmod 755 "$BIN.tmp"
  mv -f "$BIN.tmp" "$BIN"
  printf '%s\n' "$BOOSTEROID_BIN" > "$MARKER"
}

adopt_client_update() {
  cp -f "$WRAP" "$BIN.new" || return 1
  chmod 755 "$BIN.new"

  interp=$("$PATCHELF" --print-interpreter "$BOOSTEROID_BIN") || { rm -f "$BIN.new"; return 1; }
  rpath=$("$PATCHELF" --print-rpath "$BOOSTEROID_BIN") || { rm -f "$BIN.new"; return 1; }
  "$PATCHELF" --set-interpreter "$interp" --set-rpath "$rpath" "$BIN.new" \
    || { rm -f "$BIN.new"; return 1; }

  # Sanity-Check: alle NEEDED-Libs aufloesbar? Sonst bleibt die alte Binary.
  if "$interp" --list "$BIN.new" 2>&1 | grep -q "not found"; then
    rm -f "$BIN.new"
    return 1
  fi

  mv -f "$BIN.new" "$BIN"
}

# Eigene Shortcuts des Clients (Exec=$APP_DIR/Boosteroid) auf den Nix-Wrapper
# umbiegen: nach einem In-App-Update liegt dort sonst eine ungepatchte ELF.
fix_client_shortcuts() {
  dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  [ -d "$dir" ] || return 0
  # Stabiler Profilpfad (ueberlebt Nix-Updates) statt Store-Pfad.
  launcher=$(command -v boosteroid 2>/dev/null || true)
  [ -n "$launcher" ] || launcher=${BOOSTEROID_LAUNCHER:-}
  [ -n "$launcher" ] || return 0
  for f in "$dir"/*.desktop; do
    [ -f "$f" ] || continue
    grep -qF "$WRAP" "$f" || continue
    sed -i \
      -e "s|^Exec=\"$WRAP\"|Exec=\"$launcher\"|" \
      -e "s|^Exec=$WRAP|Exec=$launcher|" "$f" || true
  done
  return 0
}

# 1) Neues Nix-Paket (Pin erneuert) hat Vorrang: Store-Binary uebernehmen.
if [ ! -e "$BIN" ] || [ "$(cat "$MARKER" 2>/dev/null)" != "$BOOSTEROID_BIN" ]; then
  install_store_bin
# 2) In-App-Update des Clients uebernehmen ($WRAP ist dann eine ELF).
elif is_elf "$WRAP" && ! cmp -s "$WRAP" "$BIN"; then
  adopt_client_update || echo "WARNUNG: Boosteroid-Update nicht uebernommen" >&2
fi

fix_client_shortcuts

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
