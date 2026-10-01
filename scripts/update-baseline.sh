#!/usr/bin/env bash
# Aktualisiert die getrackte Noctalia-Baseline eines Pull-Hosts aus dessen
# LIVE-settings.toml (per SSH). Zeigt vorher den Diff und fragt nach.
#
# Verwendung:
#   scripts/update-baseline.sh <user> [ssh-host] [-y]
#
#   <user>      z.B. lion oder backbone
#   [ssh-host]  SSH-Ziel (default: <user>); muss per SSH erreichbar sein
#   -y|--yes    ohne Rueckfrage committen/pushen
#
# Beispiele:
#   scripts/update-baseline.sh lion              # nutzt ssh-Host "lion"
#   scripts/update-baseline.sh backbone styx     # falls styx per ssh erreichbar
set -euo pipefail

assume_yes=0
args=()
for a in "$@"; do
  case "$a" in
    -y|--yes) assume_yes=1 ;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) args+=("$a") ;;
  esac
done

user="${args[0]:-}"
host="${args[1]:-$user}"

if [[ -z "$user" ]]; then
  echo "Verwendung: $0 <user> [ssh-host] [-y]" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rel="home/$user/state/noctalia/settings.toml"
remote="/etc/nixos/$rel"
local_baseline="$repo_root/$rel.baseline"

if [[ ! -f "$local_baseline" ]]; then
  echo "FEHLER: Baseline nicht gefunden: $local_baseline" >&2
  echo "        Gibt es die Baseline fuer '$user'?" >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

echo "==> Hole $host:$remote"
if ! scp -q -o BatchMode=yes "$host:$remote" "$tmp"; then
  echo "FEHLER: Konnte $remote nicht von '$host' holen (SSH erreichbar?)." >&2
  exit 1
fi

echo "==> Vergleich: Baseline -> Live"
if diff -u "$local_baseline" "$tmp"; then
  echo "==> Keine Aenderung — Baseline ist aktuell. Nichts zu tun."
  exit 0
fi

if [[ "$assume_yes" -ne 1 ]]; then
  echo
  read -rp "Diese Aenderungen als neue Baseline uebernehmen? [j/N] " ans || ans=""
  if [[ ! "$ans" =~ ^[jJyY]$ ]]; then
    echo "Abgebrochen."
    exit 0
  fi
fi

cp -a "$tmp" "$local_baseline"
cd "$repo_root"
git add "$rel.baseline"
git commit -m "noctalia: $user baseline aktualisiert"
git push
echo "==> Baseline fuer '$user' aktualisiert und gepusht."
