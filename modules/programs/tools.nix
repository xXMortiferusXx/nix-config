# Zusatz-Tools und Fish-Aliase für System-/Nix-Pflege.
{ config, pkgs, ... }:
let
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

  # Update + Build testen, OHNE bei Fehlern einen kaputten flake.lock zu hinterlassen.
  # Erfolg: neuer Lock bleibt stehen. Fehler: alter Lock wird restauriert.
  nixCheck = pkgs.writeShellScriptBin "nix-check" ''
    set -u
    ${uiLib}
    repo=/etc/nixos
    host=$(hostname)
    trace=""
    if [ "''${1:-}" = "--trace" ]; then trace="--show-trace"; fi

    backup=$(mktemp)
    trap 'rm -f "$backup"' EXIT
    cp "$repo/flake.lock" "$backup"

    ui_title "Nix-Check"
    ui_kv "Host" "$host"
    ui_kv "Flake" "$repo"

    np_path() { nix eval --impure --raw --expr '(builtins.getFlake "/etc/nixos").inputs.nixpkgs.outPath' 2>/dev/null || true; }
    old_np=$(np_path)

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
      ui_err "Build fehlgeschlagen"
      ui_info "flake.lock zurückgesetzt · System unangetastet"
      ui_info "Vollständiger Trace: nix-check --trace"
      exit 1
    fi
    ui_ok "Build ok"

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
  ] ++ [ nixCheck nixRebootCheck nixosUpdate nixSync audioRate micCheck ];

  programs.fish.shellAliases = {

    # System & Update (hostname wird per Fish-Funktion dynamisch aufgelöst)
    nix-search = "nix search nixpkgs";
    # nix-check ist ein eigenes Skript (siehe nixCheck oben) - restauriert den Lock bei Fehlern.
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
