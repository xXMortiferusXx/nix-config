# Zusatz-Tools und Fish-Aliase für System-/Nix-Pflege.
{ config, pkgs, lib, ... }:
let
  # Nur Hosts mit NVIDIA-Treiber (nex) bekommen nvidia-track und den
  # Treiber-Schritt in nix-check; auf allen anderen bleibt alles unveraendert.
  nvidiaHost = builtins.elem "nvidia" config.services.xserver.videoDrivers;

  # Was der Auto-Commit in nix-check anfassen darf (bewusst nicht `git add -A`,
  # damit eigene Arbeit und settings.toml unberuehrt bleiben).
  commitPaths = [ "flake.lock" ]
    ++ lib.optional nvidiaHost "modules/hardware/nvidia-driver.json"
    ++ [ "pkgs/boosteroid/pin.json" ];

  # Gemeinsames Terminal-Design fuer alle Nix-Tools. Farben/Symbole nur bei TTY
  # (und nicht bei NO_COLOR/TERM=dumb), damit Pipes/Logs sauber bleiben.
  uiLib = ''
    if [ -t 1 ] && [ -z "''${NO_COLOR:-}" ] && [ "''${TERM:-}" != "dumb" ]; then
      ACC=$'\033[38;5;39m'; OKC=$'\033[38;5;42m'; WRN=$'\033[38;5;214m'
      ERRC=$'\033[38;5;203m'; DIM=$'\033[38;5;245m'; BLD=$'\033[1m'; RST=$'\033[0m'
    else
      ACC=""; OKC=""; WRN=""; ERRC=""; DIM=""; BLD=""; RST=""
    fi
    ui_title() { printf '\n%s%s%s\n' "$BLD$ACC" "$1" "$RST"; printf '%s' "$DIM"; printf '%.0s─' $(seq 1 "''${2:-52}"); printf '%s\n' "$RST"; }
    ui_rule()  { printf '%s' "$DIM"; printf '%.0s─' $(seq 1 "''${1:-52}"); printf '%s\n' "$RST"; }
    ui_step()  { printf '\n%s▸%s %s%s%s\n' "$ACC" "$RST" "$BLD" "$1" "$RST"; }
    ui_kv()    { printf '  %s%-13s%s %s\n' "$DIM" "$1" "$RST" "$2"; }
    ui_ok()    { printf '  %s✔%s %s\n' "$OKC" "$RST" "$1"; }
    ui_warn()  { printf '  %s▲%s %s\n' "$WRN" "$RST" "$1"; }
    ui_err()   { printf '  %s✖%s %s\n' "$ERRC" "$RST" "$1"; }
    ui_info()  { printf '  %s•%s %s\n' "$DIM" "$RST" "$1"; }
  '';

  # Reboot-Einschaetzung: vergleicht /run/booted-system mit einem Ziel-System
  # (Default /run/current-system, optional z.B. ./result vor dem Switch).
  nixRebootCheck = pkgs.writeShellScriptBin "nix-reboot-check" ''
    set -u
    ${uiLib}
    target="''${1:-/run/current-system}"
    booted=/run/booted-system
    changed() { [ "$(readlink -f "$booted/$1" 2>/dev/null)" != "$(readlink -f "$target/$1" 2>/dev/null)" ]; }
    boot_kver=$(ls "$booted/kernel-modules/lib/modules/" 2>/dev/null | head -1)
    new_kver=$(ls "$target/kernel-modules/lib/modules/" 2>/dev/null | head -1)
    ui_step "Reboot-Status"
    if [ -n "$boot_kver" ] && [ -n "$new_kver" ] && [ "$boot_kver" != "$new_kver" ]; then
      ui_warn "Reboot nötig · neuer Kernel ($boot_kver → $new_kver)"
    elif changed kernel-modules; then
      ui_warn "Reboot empfohlen · Kernel-Module geändert (z. B. NVIDIA-Treiber)"
    elif changed kernel || changed initrd; then
      ui_warn "Reboot empfohlen · Kernel/initrd neu gebaut"
    elif changed init; then
      ui_warn "Reboot empfohlen · systemd/PID1 geändert"
    elif changed firmware; then
      ui_warn "Reboot empfohlen · Firmware geändert"
    else
      ui_ok "Kein Reboot nötig · nur Userspace"
    fi
  '';

  # Host-agnostischer Update-Befehl, z.B. fuer den "Nix Monitor"-Button in Noctalia.
  # Kein hartkodiertes #hostname; gibt am Ende die Reboot-Einschaetzung aus.
  nixosUpdate = pkgs.writeShellScriptBin "nixos-update" ''
    set -u
    ${uiLib}
    cd /etc/nixos || exit 1
    host=$(hostname)
    ui_title "NixOS Update"
    ui_kv "Host" "$host"
    ui_kv "Flake" "/etc/nixos"

    ui_step "flake update"
    if ! nix flake update; then
      ui_err "flake update fehlgeschlagen"
      exit 1
    fi

    ui_step "switch"
    if ! sudo nixos-rebuild switch --flake ".#$host"; then
      ui_err "switch fehlgeschlagen"
      exit 1
    fi

    nix-reboot-check
  '';

  # Reparatur-Sync als Skript (statt Fish-Alias): holt origin/main hart
  # zurueck, aktualisiert die Inputs und schaltet. Das `nix flake update`
  # ist bewusst enthalten (kein Downgrade auf einen alten Lock).
  nixSync = pkgs.writeShellScriptBin "nix-sync" ''
    set -u
    ${uiLib}
    repo=/etc/nixos
    host=$(hostname)
    cd "$repo" || exit 1

    ui_title "Nix-Sync"
    ui_kv "Host" "$host"
    ui_kv "Flake" "$repo"

    ui_step "Repo aktualisieren"
    if ! { git reset --hard origin/main && git pull; }; then
      ui_err "git reset/pull fehlgeschlagen"
      exit 1
    fi
    ui_ok "auf origin/main"

    ui_step "flake update"
    if ! nix flake update; then
      ui_err "flake update fehlgeschlagen"
      exit 1
    fi

    ui_step "switch"
    if ! sudo nixos-rebuild switch --flake ".#$host"; then
      ui_err "switch fehlgeschlagen"
      exit 1
    fi

    nix-reboot-check
    echo
    ui_rule
    ui_ok "Sync abgeschlossen"
  '';

  # Zeigt Rate/Quantum/ERR der gerade laufenden Audio-Knoten (GC7-Praefix gekuerzt).
  # Nuetzlich, weil weder Player noch DAC die tatsaechlich ausgehandelte Rate anzeigen.
  audioRate = pkgs.writeShellScriptBin "audio-rate" ''
    set -u
    ${uiLib}
    ui_title "Aktive Audio-Knoten" 60
    rows=$(pw-top -b -n 2 2>/dev/null | awk -v okc="$OKC" -v errc="$ERRC" -v dim="$DIM" -v rst="$RST" '
      $2 == "ID" { snap = snap + 1; next }
      snap >= 2 && ($3 + 0) > 0 {
        name = "";
        for (i = 13; i <= NF; i++) name = name (i > 13 ? " " : "") $i;
        sub(/alsa_(output|input)\.usb-Creative_Technology_Ltd_Sound_Blaster_GC7_[A-Za-z0-9]+-03\./, "", name);
        err = ($9 + 0 > 0) ? errc "ERR " $9 rst : okc "OK" rst;
        printf "  %-30s %s%7s Hz%s  %sq=%-5s%s  %s\n", name, dim, $4, rst, dim, $3, rst, err;
        n++;
      }
      END { exit (n > 0 ? 0 : 1) }')
    if [ -z "$rows" ]; then
      ui_warn "keine aktiven Knoten (alles suspendiert)"
    else
      printf '%s\n' "$rows"
    fi
  '';

  # Misst den Mikrofon-Signalweg objektiv: 12 s Aufnahme (8 s sprechen, 4 s
  # still) und Auswertung von Pegel, Rauschboden, SNR, Crest, Clipping, DC.
  # Mit Datei-Argument wird eine vorhandene WAV nur analysiert (kein Recording).
  micCheck = pkgs.writeShellScriptBin "mic-check" ''
    set -u
    dur=12
    file=/tmp/mic-check.wav
    if [ "''${1:-}" = "-d" ] && [ $# -ge 2 ]; then
      dur="$2"; shift 2
    fi
    if [ $# -ge 1 ]; then
      file="$1"
      if [ ! -f "$file" ]; then
        echo "mic-check: '$file' nicht gefunden" >&2
        exit 1
      fi
    else
      echo "Aufnahme ''${dur}s: bitte $((dur - 4))s normal sprechen, dann 4s still bleiben."
      # pw-record liefert hier rc=1 trotz vollstaendiger Datei -> Groesse pruefen.
      pw-record --rate 48000 --channels 2 --channel-map FL,FR --format s24 \
        --container wav -n $((dur * 48000)) "$file" || true
      if [ ! -f "$file" ] || [ "$(stat -c %s "$file" 2>/dev/null || echo 0)" -lt $((dur * 48000 * 6 + 44)) ]; then
        echo "mic-check: Aufnahme unvollstaendig ($file)" >&2
        exit 1
      fi
    fi

    ${pkgs.python3}/bin/python3 - "$file" <<'PYEOF'
import sys, os, wave, struct, math

path = sys.argv[1]
w = wave.open(path, "rb")
rate = w.getframerate(); ch = w.getnchannels()
sw = w.getsampwidth(); nf = w.getnframes()
raw = w.readframes(nf)
w.close()

bits = sw * 8
fs = float(1 << (bits - 1))

if sw == 3:
    vals = [int.from_bytes(raw[i:i+3], "little", signed=True)
            for i in range(0, len(raw) - 2, 3)]
elif sw == 2:
    vals = list(struct.unpack("<%dh" % (len(raw) // 2), raw))
elif sw == 4:
    vals = list(struct.unpack("<%di" % (len(raw) // 4), raw))
else:
    sys.exit("Bittiefe %d wird nicht unterstuetzt" % bits)

if not vals:
    sys.exit("Leere Aufnahme")

L = vals[0::ch]
R = vals[1::ch] if ch > 1 else L

def rms(x):
    if not x:
        return 0.0
    s = 0.0
    for v in x:
        s += float(v) * float(v)
    return math.sqrt(s / len(x))

def db(x):
    return 20.0 * math.log10(max(x / fs, 1e-12))

flen = max(1, int(rate * 0.02))
fr = []
for x in (L, R):
    for i in range(0, len(x) - flen + 1, flen):
        seg = x[i:i + flen]
        s = 0.0
        for v in seg:
            s += float(v) * float(v)
        fr.append(math.sqrt(s / flen))
fr.sort()

def pct(p):
    if not fr:
        return 0.0
    i = int(round(p * (len(fr) - 1)))
    i = max(0, min(i, len(fr) - 1))
    return fr[i]

peak = max(abs(min(L)), abs(max(L)), abs(min(R)), abs(max(R)))
speech = pct(0.90)
noise = pct(0.10)
snr = db(speech) - db(noise)
peak_db = db(peak)
crest = peak_db - db(speech)
clip = sum(1 for v in vals if abs(v) >= fs - 1)
clip_pct = 100.0 * clip / len(vals)
dc = 100.0 * (sum(vals) / len(vals)) / fs

tty = sys.stdout.isatty() and not os.environ.get("NO_COLOR") and os.environ.get("TERM") != "dumb"

def c(code, text):
    return ("\033[" + code + "m" + text + "\033[0m") if tty else text

ACC = "38;5;39"; OKC = "38;5;42"; WRN = "38;5;214"
ERRC = "38;5;203"; DIM = "38;5;245"; BLD = "1"

print()
print(c(BLD + ";" + ACC, "Mikrofon-Check"))
print(c(DIM, "─" * 52))
print("  " + c(DIM, "%-12s" % "Datei") + " " + path)
print("  " + c(DIM, "%-12s" % "Format") + " " + ("%d Hz · %d Kanal(e) · %d Bit" % (rate, ch, bits)))
print("  " + c(DIM, "%-12s" % "Dauer") + " " + ("%.1f s" % (nf / float(rate))))

def row(k, v):
    print("    " + c(DIM, "%-14s" % k) + " " + v)

print()
print("  " + c(ACC, "Pegel"))
row("Peak", ("%6.1f dBFS" % peak_db) + ("  " + c(WRN, "Clipping-Gefahr") if peak_db > -3 else ""))
row("RMS gesamt", "%6.1f dBFS" % db((rms(L) + rms(R)) / 2.0))
row("Sprache (P90)", "%6.1f dBFS" % db(speech))
row("Stille  (P10)", "%6.1f dBFS" % db(noise))
row("SNR", "%6.1f dB" % snr)
row("Crest-Faktor", "%6.1f dB" % crest)
row("Clipping", ("%7.3f %% der Samples" % clip_pct) + ("  " + c(ERRC, "zu hoch") if clip_pct > 0 else ""))
row("DC-Offset", "%7.3f %%" % dc)
row("Kanal L/R", "%6.1f / %6.1f dBFS" % (db(rms(L)), db(rms(R))))

def ok(t):   print("    " + c(OKC, "✔") + " " + t)
def warn(t): print("    " + c(WRN, "▲") + " " + t)
def info(t): print("    " + c(DIM, "•") + " " + t)

print()
print("  " + c(ACC, "Bewertung"))
if snr >= 45:
    ok("SNR sehr gut (>= 45 dB)")
elif snr >= 30:
    ok("SNR gut (30–45 dB)")
elif snr >= 20:
    warn("SNR ausreichend (20–30 dB) · Störgeräuschunterdrückung sinnvoll")
else:
    warn("SNR schwach (< 20 dB) · Umgebung/Mikrofonabstand prüfen")
if peak_db > -3:
    warn("Peak > -3 dBFS · Pegel senken (Clipping-Gefahr)")
gain = -18.0 - db(speech)
if gain > 3:
    info("Empfehlung: Pegel um ca. %+.0f dB anheben (Ziel ~ -18 dBFS Sprache)" % gain)
elif gain < -3:
    info("Empfehlung: Pegel um ca. %+.0f dB senken (Ziel ~ -18 dBFS Sprache)" % gain)
else:
    ok("Sprachpegel im Zielbereich (~ -18 dBFS)")

print()
print(c(DIM, "  Akustisches Rauschen (Lüfter/Raum) skaliert mit dem Pegel → SNR bleibt;"))
print(c(DIM, "  elektronisches Rauschen skaliert nicht → SNR steigt. Pegel bis knapp unter"))
print(c(DIM, "  Clipping ausreizen; gegen akustischen Lärm hilft nur Abstand."))
print()
print(c(DIM, "  P10/P90 sind robuste Frame-Pegel (20 ms); Raum-/Lüftergeräusche stecken im"))
print(c(DIM, "  Rauschboden. Werte sind umgebungsabhängig, nicht absolut."))

PYEOF
  '';

  # Holt die neueste NVIDIA-Version direkt aus NVIDIAs Download-Index und
  # schreibt Version + Hashes nach modules/hardware/nvidia-driver.json.
  # Ohne neues Release: ein HTTP-GET, sonst nichts. Gebaut/geprueft wird das
  # Ganze in `nix-check`.
  nvidiaTrack = pkgs.writeShellScriptBin "nvidia-track" ''
    set -u
    ${uiLib}
    repo=/etc/nixos
    json=$repo/modules/hardware/nvidia-driver.json
    index=https://download.nvidia.com/XFree86/Linux-x86_64
    jq=${pkgs.jq}/bin/jq
    curl=${pkgs.curl}/bin/curl
    nixbin=${pkgs.nix}/bin

    ui_title "NVIDIA-Treiber"

    if [ ! -f "$json" ]; then
      ui_err "$json fehlt"
      exit 1
    fi

    if [ "''${1:-}" = "--reset" ]; then
      $jq '.blocked = []' "$json" > "$json.tmp" && mv "$json.tmp" "$json"
      ui_ok "Sperrliste geleert"
      exit 0
    fi

    cur=$($jq -r .version "$json")
    ui_kv "Pin" "$cur"

    # Der Index nutzt je nach Server ' oder "; auf " normalisieren.
    newest=$($curl -fsSL --max-time 25 "$index/" \
      | tr "'" '"' \
      | grep -oE 'href="[0-9][^"]*/"' \
      | sed -E 's/href="([^"]*)\/"/\1/' \
      | sort -V | tail -1)

    if [ -z "''${newest:-}" ]; then
      ui_err "NVIDIA-Index nicht lesbar"
      exit 1
    fi

    if [ "$newest" = "$cur" ]; then
      ui_ok "$cur · aktuell"
      exit 0
    fi
    if [ "$(printf '%s\n%s\n' "$cur" "$newest" | sort -V | tail -1)" = "$cur" ]; then
      ui_info "Index nennt $newest (aelter als Pin) · nichts zu tun"
      exit 0
    fi
    if $jq -e --arg v "$newest" '.blocked | index($v)' "$json" >/dev/null 2>&1; then
      ui_warn "$newest · blockiert (Freigabe: nvidia-track --reset)"
      exit 0
    fi

    ui_kv "Neu" "$newest"
    ui_step "Hashes laden"

    # .run ist ein einzelnes File (fetchurl); die drei Tarballs werden entpackt
    # gehasht (fetchzip) -> dafuer nix-prefetch-url --unpack.
    flat() { $nixbin/nix store prefetch-file --json "$1" 2>/dev/null | $jq -r .hash; }
    unpacked() {
      b32=$($nixbin/nix-prefetch-url --unpack "$1" 2>/dev/null) || return 1
      [ -n "$b32" ] || return 1
      $nixbin/nix hash convert --hash-algo sha256 --to sri "$b32"
    }

    run=$(flat "https://us.download.nvidia.com/XFree86/Linux-x86_64/$newest/NVIDIA-Linux-x86_64-$newest.run")
    [ -n "''${run:-}" ] || { ui_err "Download .run fehlgeschlagen"; exit 1; }

    open=$(unpacked "https://github.com/NVIDIA/open-gpu-kernel-modules/archive/$newest.tar.gz")
    [ -n "''${open:-}" ] || { ui_err "Download open-gpu-kernel-modules fehlgeschlagen"; exit 1; }

    settings=$(unpacked "https://github.com/NVIDIA/nvidia-settings/archive/$newest.tar.gz")
    [ -n "''${settings:-}" ] || { ui_err "Download nvidia-settings fehlgeschlagen"; exit 1; }

    persist=$(unpacked "https://github.com/NVIDIA/nvidia-persistenced/archive/$newest.tar.gz")
    [ -n "''${persist:-}" ] || { ui_err "Download nvidia-persistenced fehlgeschlagen"; exit 1; }

    $jq -n --arg v "$newest" --arg run "$run" --arg open "$open" \
      --arg settings "$settings" --arg persist "$persist" \
      --argjson blocked "$($jq '.blocked // []' "$json")" \
      '{version: $v, blocked: $blocked, sha256_64bit: $run,
        openSha256: $open, settingsSha256: $settings,
        persistencedSha256: $persist}' > "$json.tmp" && mv "$json.tmp" "$json" \
      || { ui_err "JSON schreiben fehlgeschlagen"; exit 1; }

    ui_ok "$newest eingetragen"
    ui_info "Bau/Pruefung: nix-check"
  '';

  # Haelt pkgs/boosteroid/pin.json aktuell. Upstream liefert eine unversionierte
  # Tar; sobald sich der Inhalt aendert, wuerde `fetchurl` mit Hash-Mismatch
  # scheitern (also auch eine Neuinstallation). Deshalb: billiger HEAD-Vergleich
  # ueber ETag, nur bei Aenderung Download + Datum/SRI-Hash, danach eine
  # Strukturpruefung der Tar (kein Build noetig - es wird nichts kompiliert,
  # das Paket patcht nur Interpreter/RPATH). `--build` macht die volle Probe.
  # Nur auf dem Pflege-Host mit git-Identitaet (nex) – andere Hosts brechen ab.
  boosteroidTrack = pkgs.writeShellScriptBin "boosteroid-track" ''
    set -u
    do_build=0
    for a in "$@"; do
      case "$a" in
        --build) do_build=1 ;;
      esac
    done
    ${uiLib}
    repo=/etc/nixos
    json=$repo/pkgs/boosteroid/pin.json
    url=https://boosteroid.com/linux/installer/boosteroid_portable.tar
    ua=Mozilla/5.0
    jq=${pkgs.jq}/bin/jq
    curl=${pkgs.curl}/bin/curl
    tar=${pkgs.gnutar}/bin/tar
    datebin=${pkgs.coreutils}/bin/date
    statbin=${pkgs.coreutils}/bin/stat
    nixbin=${pkgs.nix}/bin/nix

    ui_title "Boosteroid-Client"

    if [ ! -f "$json" ]; then
      ui_err "$json fehlt"
      exit 1
    fi
    if [ -z "$(git -C "$repo" config user.email 2>/dev/null || true)" ]; then
      ui_info "keine git-Identitaet · nur auf nex"
      exit 0
    fi

    cur=$($jq -r '.date // "?"' "$json")
    cur_etag=$($jq -r '.etag // ""' "$json")
    ui_kv "Pin" "$cur"

    if ! hdr=$($curl -fsSIL -A "$ua" --max-time 25 "$url" 2>/dev/null); then
      ui_warn "Upstream nicht erreichbar · Pin unveraendert"
      exit 0
    fi
    hdr=$(printf '%s\n' "$hdr" | tr -d '\r')
    etag=$(printf '%s\n' "$hdr" | sed -n 's/^[Ee][Tt][Aa][Gg]: *//p' | tail -1)
    size=$(printf '%s\n' "$hdr" | sed -n 's/^[Cc]ontent-[Ll]ength: *//p' | tail -1)
    mtime=$(printf '%s\n' "$hdr" | sed -n 's/^[Ll]ast-[Mm]odified: *//p' | tail -1)

    if [ -n "$etag" ] && [ "$etag" = "$cur_etag" ]; then
      ui_ok "$cur · aktuell"
      exit 0
    fi
    ui_kv "Upstream" "''${mtime:-unbekannt}"
    ui_step "Download + Pruefung"

    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    if ! $curl -fsSL -A "$ua" --max-time 900 -o "$tmp/pkg.tar" "$url"; then
      ui_err "Download fehlgeschlagen · Pin unveraendert"
      exit 1
    fi
    old_hash=$($jq -r '.hash' "$json")
    new_hash=$($nixbin hash file --type sha256 --sri "$tmp/pkg.tar" 2>/dev/null) || new_hash=""
    if [ -z "$new_hash" ]; then
      ui_err "Hash fehlgeschlagen · Pin unveraendert"
      exit 1
    fi

    if [ "$new_hash" = "$old_hash" ]; then
      $jq --arg etag "$etag" --argjson size "''${size:-0}" \
        '.etag = $etag | .size = $size' "$json" > "$json.tmp" \
        && mv "$json.tmp" "$json"
      ui_ok "Inhalt unveraendert · nur ETag nachgezogen"
      exit 0
    fi

    listing=$($tar tf "$tmp/pkg.tar" | sed 's|^\./||')
    count=$(printf '%s\n' "$listing" | grep -c . || true)
    if [ "$count" -ne 1 ] || [ "$listing" != "Boosteroid" ]; then
      ui_err "Tar-Aufbau unerwartet ($count Eintraege) · Pin unveraendert"
      exit 1
    fi

    $tar xf "$tmp/pkg.tar" -C "$tmp" || { ui_err "Tar nicht lesbar · Pin unveraendert"; exit 1; }
    magic=$(head -c 4 "$tmp/Boosteroid" 2>/dev/null | od -An -tx1 | tr -d ' \n')
    machine=$(od -An -tx1 -j 18 -N 2 "$tmp/Boosteroid" 2>/dev/null | tr -d ' \n')
    bsize=$($statbin -c %s "$tmp/Boosteroid" 2>/dev/null || echo 0)
    if [ "$magic" != "7f454c46" ] || [ "$machine" != "3e00" ] || [ "''${bsize:-0}" -lt 50000000 ]; then
      ui_err "Binary unerwartet (kein x86-64-ELF oder zu klein) · Pin unveraendert"
      exit 1
    fi
    new_date=$($datebin -r "$tmp/Boosteroid" +%F 2>/dev/null || $datebin +%F)
    ui_kv "Neu" "$new_date"
    ui_ok "Struktur ok · $((bsize / 1048576)) MB"

    cp "$json" "$json.bak"
    $jq -n --arg date "$new_date" --arg etag "$etag" --argjson size "''${size:-0}" \
      --arg hash "$new_hash" \
      '{date: $date, etag: $etag, size: $size, hash: $hash}' > "$json.tmp" \
      && mv "$json.tmp" "$json" \
      || { mv "$json.bak" "$json"; ui_err "JSON schreiben fehlgeschlagen"; exit 1; }

    if [ "$do_build" = 1 ]; then
      ui_step "Bau pruefen (--build)"
      if ! ( cd "$repo" && NIXPKGS_ALLOW_UNFREE=1 $nixbin build --impure --no-link \
               --expr "let f = builtins.getFlake \"path:$repo\"; p = f.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}; in p.callPackage $repo/pkgs/boosteroid { }" \
               >/dev/null 2>&1 ); then
        mv "$json.bak" "$json"
        ui_err "Paket baut nicht · Pin zurueckgenommen"
        exit 1
      fi
    fi
    rm -f "$json.bak"

    ui_ok "$new_date eingetragen"
    ui_info "Commit folgt mit nix-check"
  '';

  # Update + Build testen, OHNE bei Fehlern einen kaputten flake.lock zu hinterlassen.
  # Erfolg: neuer Lock bleibt stehen, Lock + Treiber-Pin werden committet/gepusht.
  # Fehler: alter Lock (und ggf. Pin) wird restauriert, die Version wird blockiert.
  nixCheck = pkgs.writeShellScriptBin "nix-check" ''
    set -u
    ${uiLib}
    repo=/etc/nixos
    host=$(hostname)
    trace=""
    do_commit=1
    for a in "$@"; do
      case "$a" in
        --trace) trace="--show-trace" ;;
        --no-commit) do_commit=0 ;;
      esac
    done

    backup=$(mktemp)
    json_backup=$(mktemp)
    pin_backup=$(mktemp)
    trap 'rm -f "$backup" "$json_backup" "$pin_backup"' EXIT
    cp "$repo/flake.lock" "$backup"
    cp "$repo/pkgs/boosteroid/pin.json" "$pin_backup"
    ${lib.optionalString nvidiaHost ''
    json=$repo/modules/hardware/nvidia-driver.json
    cp "$json" "$json_backup"
    ''}

    ui_title "Nix-Check"
    ui_kv "Host" "$host"
    ui_kv "Flake" "$repo"

    np_path() { nix eval --impure --raw --expr '(builtins.getFlake "/etc/nixos").inputs.nixpkgs.outPath' 2>/dev/null || true; }
    old_np=$(np_path)

    ${lib.optionalString nvidiaHost ''
    ui_step "nvidia-track"
    ${nvidiaTrack}/bin/nvidia-track || ui_warn "nvidia-track fehlgeschlagen · Pin unverändert"
    ''}

    ui_step "boosteroid-track"
    ${boosteroidTrack}/bin/boosteroid-track || ui_warn "boosteroid-track fehlgeschlagen · Pin unverändert"

    ui_step "flake update"
    if ! (cd "$repo" && nix flake update); then
      cp "$backup" "$repo/flake.lock"
      ui_err "flake update fehlgeschlagen · Lock unverändert"
      exit 1
    fi
    ui_ok "Lock aktualisiert"

    # Ankuendigung, die nixpkgs bei unstable nicht liefert: was wurde neu entfernt/umbenannt?
    new_np=$(np_path)
    if [ -n "$old_np" ] && [ -n "$new_np" ] && [ "$old_np" != "$new_np" ] \
       && [ -f "$old_np/pkgs/top-level/aliases.nix" ] && [ -f "$new_np/pkgs/top-level/aliases.nix" ]; then
      aliases=$(diff -U0 "$old_np/pkgs/top-level/aliases.nix" "$new_np/pkgs/top-level/aliases.nix" 2>/dev/null \
        | grep -E '^\+.*= *(throw|warnAlias)' \
        | sed 's/^+ *//' | head -25 || true)
      if [ -n "$aliases" ]; then
        ui_step "nixpkgs · neu entfernt/umbenannt"
        printf '%s\n' "$aliases" | while IFS= read -r l; do ui_warn "$l"; done
      fi
    fi

    ui_step "build ($host)"
    if ! (cd "$repo" && nixos-rebuild build --flake ".#$host" $trace); then
      cp "$backup" "$repo/flake.lock"
      echo
      ${lib.optionalString nvidiaHost ''
      # Neuen Treiber-Pin zuruecknehmen und die Version sperren, damit der
      # naechste Lauf nicht an derselben Stelle scheitert.
      new_ver=$(${pkgs.jq}/bin/jq -r .version "$json" 2>/dev/null || true)
      old_ver=$(${pkgs.jq}/bin/jq -r .version "$json_backup" 2>/dev/null || true)
      if [ -n "''${new_ver:-}" ] && [ "$new_ver" != "$old_ver" ]; then
        cp "$json_backup" "$json"
        ${pkgs.jq}/bin/jq --arg v "$new_ver" \
          '.blocked = ((.blocked // []) + [$v] | unique)' "$json" > "$json.tmp" \
          && mv "$json.tmp" "$json"
        ui_warn "nvidia $new_ver blockiert · Freigabe: nvidia-track --reset"
      fi
      ''}
      ui_err "Build fehlgeschlagen"
      ui_info "flake.lock zurückgesetzt · System unangetastet"
      cp "$pin_backup" "$repo/pkgs/boosteroid/pin.json"
      ui_info "boosteroid-Pin zurückgesetzt"
      ui_info "Vollständiger Trace: nix-check --trace"
      exit 1
    fi
    ui_ok "Build ok"

    ${lib.optionalString nvidiaHost ''
    src=$repo/result/etc/nvidia/driver-source
    if [ -f "$src" ]; then ui_kv "nvidia" "$(cat "$src")"; fi
    ''}

    ui_step "Paket-Änderungen"
    diff_out=$(nvd diff -s /run/current-system "$repo/result" 2>/dev/null || true)
    ver_lines=$(printf '%s\n' "$diff_out" | grep -E '^\[(U|A|R)' || true)
    if [ -n "$ver_lines" ]; then
      printf '%s\n' "$ver_lines"
    else
      ui_info "keine Versionswechsel"
    fi
    rebuilds=$(printf '%s\n' "$diff_out" | grep -cE '^\[C' || true)
    if [ "''${rebuilds:-0}" -gt 0 ]; then
      ui_info "$rebuilds weitere Rebuilds ohne Versionswechsel"
    fi

    ${nixRebootCheck}/bin/nix-reboot-check "$repo/result"

    # Nur Lock (+ Treiber-Pin) committen, nie fremde Aenderungen: `--only`
    # laesst bereits gestagte Dateien anderer Arbeit unberuehrt.
    ui_step "Commit & Push"
    paths=( ${lib.concatStringsSep " " commitPaths} )
    if [ "$do_commit" = 0 ]; then
      ui_info "--no-commit · uebersprungen"
    elif [ "$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)" != "main" ]; then
      ui_warn "nicht auf main · nichts committet"
    elif [ -d "$repo/.git/rebase-merge" ] || [ -d "$repo/.git/rebase-apply" ] || [ -f "$repo/.git/MERGE_HEAD" ]; then
      ui_warn "Rebase/Merge aktiv · nichts committet"
    else
      ( cd "$repo" && git add -- "''${paths[@]}" )
      if ( cd "$repo" && git diff --cached --quiet -- "''${paths[@]}" ); then
        ui_info "keine Aenderungen an Lock/Pin"
      else
        msg="chore(lock): nix-check ok $(date +%F)"
        if ( cd "$repo" && git commit -q --only -m "$msg" -m "$ver_lines" -- "''${paths[@]}" ); then
          ui_ok "committet · $msg"
          if ( cd "$repo" && git push -q origin main 2>/dev/null ); then
            ui_ok "gepusht"
          else
            ui_warn "push fehlgeschlagen · Commit bleibt lokal"
          fi
        else
          ui_warn "commit fehlgeschlagen · Aenderungen bleiben lokal"
        fi
      fi
    fi

    echo
    ui_rule
    ui_ok "OK · Lock behalten · Switch: nix-switch"
  '';
in
{
  environment.systemPackages = with pkgs; [
    iw
    jq
    ookla-speedtest
    scx.full
  ] ++ [ nixCheck nixRebootCheck nixosUpdate nixSync audioRate micCheck ]
    ++ [ boosteroidTrack ]
    ++ lib.optional nvidiaHost nvidiaTrack;

  programs.fish.shellAliases = {

    # System & Update (hostname wird per Fish-Funktion dynamisch aufgelöst)
    nix-search = "nix search nixpkgs";
    # nix-check ist ein eigenes Skript (siehe nixCheck oben) - restauriert den Lock bei
    # Fehlern, committet/pusht bei Erfolg Lock (+ NVIDIA-Pin); --no-commit zum Auslassen.
    nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#(hostname) && nix-reboot-check";
    nix-update = "pushd /etc/nixos && nix flake update && sudo nixos-rebuild switch --flake .#(hostname) && popd";
    # nix-sync ist ein eigenes Skript (siehe nixSync oben).
    night-update = "umbriel msg dpms-off && pushd /etc/nixos && nix flake update && sudo systemd-inhibit --why='Nightly Update' --mode=block nixos-rebuild switch --flake .#(hostname); popd";

    nix-clean  = "sudo nix-collect-garbage -d && sudo nix-store --optimise && sudo nixos-rebuild switch --flake /etc/nixos#(hostname)";

    # Git ohne sudo, damit die SSH-Keys des Users genutzt werden.
    conf-sync  = "pushd /etc/nixos && git add . && git commit -m \"Update: $(date +'%Y-%m-%d %H:%M')\" && git push origin main; popd";
    conf       = "cd /etc/nixos";

     scx-status = "scxtop";
  };

  programs.fish.interactiveShellInit = ''
    function nsearch
        set query (if test (count $argv) -gt 0; echo $argv[1]; else; echo "."; end)
        nix search nixpkgs "$query" --json 2>/dev/null | \
          jq -r 'to_entries[] | "\(.key | sub("^[^.]+[.][^.]+[.]"; ""))\t\(.value.version // "?")\t\(.value.description // "")" | gsub("\n"; " ")' | \
          fzf --delimiter '\t' \
              --with-nth 1,2 \
              --preview 'echo {} | cut -f3' \
              --preview-window 'right:50%:wrap' \
              --bind 'ctrl-y:execute(echo {} | cut -f1 | wl-copy)+abort' \
              --header 'STRG+Y: Paketnamen kopieren | ESC: Abbrechen'
    end
  '';
}
