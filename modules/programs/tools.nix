# Zusatz-Tools und Fish-Aliase für System-/Nix-Pflege.
{ config, pkgs, ... }:
let
  # Reboot-Einschaetzung: vergleicht /run/booted-system mit einem Ziel-System
  # (Default /run/current-system, optional z.B. ./result vor dem Switch).
  nixRebootCheck = pkgs.writeShellScriptBin "nix-reboot-check" ''
    set -u
    target="''${1:-/run/current-system}"
    booted=/run/booted-system
    changed() { [ "$(readlink -f "$booted/$1" 2>/dev/null)" != "$(readlink -f "$target/$1" 2>/dev/null)" ]; }
    boot_kver=$(ls "$booted/kernel-modules/lib/modules/" 2>/dev/null | head -1)
    new_kver=$(ls "$target/kernel-modules/lib/modules/" 2>/dev/null | head -1)
    if [ -n "$boot_kver" ] && [ -n "$new_kver" ] && [ "$boot_kver" != "$new_kver" ]; then
      echo "REBOOT: JA (neuer Kernel: $boot_kver -> $new_kver)"
    elif changed kernel-modules; then
      echo "REBOOT: empfohlen (Kernel-Module geaendert - z.B. NVIDIA-Treiber)"
    elif changed kernel || changed initrd; then
      echo "REBOOT: empfohlen (Kernel/initrd neu gebaut, laufender Kernel unveraendert)"
    elif changed init; then
      echo "REBOOT: empfohlen (systemd/PID1 geaendert)"
    elif changed firmware; then
      echo "REBOOT: empfohlen (Firmware geaendert)"
    else
      echo "REBOOT: nein (nur Userspace)"
    fi
  '';

  # Host-agnostischer Update-Befehl, z.B. fuer den "Nix Monitor"-Button in Noctalia.
  # Kein hartkodiertes #hostname; gibt am Ende die Reboot-Einschaetzung aus.
  nixosUpdate = pkgs.writeShellScriptBin "nixos-update" ''
    set -u
    cd /etc/nixos || exit 1
    nix flake update
    sudo nixos-rebuild switch --flake ".#$(hostname)"
    nix-reboot-check
  '';

  # Zeigt Rate/Quantum/ERR der gerade laufenden Audio-Knoten (GC7-Praefix gekuerzt).
  # Nuetzlich, weil weder Player noch DAC die tatsaechlich ausgehandelte Rate anzeigen.
  audioRate = pkgs.writeShellScriptBin "audio-rate" ''
    set -u
    echo "Aktive Audio-Knoten (Rate / Quantum / ERR):"
    pw-top -b -n 2 2>/dev/null | awk '
      $2 == "ID" { snap = snap + 1; next }
      snap >= 2 && ($3 + 0) > 0 {
        name = "";
        for (i = 13; i <= NF; i++) name = name (i > 13 ? " " : "") $i;
        sub(/alsa_(output|input)\.usb-Creative_Technology_Ltd_Sound_Blaster_GC7_[A-Za-z0-9]+-03\./, "", name);
        printf "  %-32s %7s Hz  quantum %-5s  ERR %s\n", name, $4, $3, $9;
      }'
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
import sys, wave, struct, math

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

print()
print("Aufnahme : %s" % path)
print("Format   : %d Hz, %d Kanal(e), %d Bit" % (rate, ch, bits))
print("Dauer    : %.1f s" % (nf / float(rate)))
print()
print("Pegel")
print("  Peak          : %6.1f dBFS" % peak_db)
print("  RMS gesamt    : %6.1f dBFS" % db((rms(L) + rms(R)) / 2.0))
print("  Sprache (P90) : %6.1f dBFS" % db(speech))
print("  Stille  (P10) : %6.1f dBFS" % db(noise))
print("  SNR           : %6.1f dB" % snr)
print("  Crest-Faktor  : %6.1f dB" % crest)
print("  Clipping      : %7.3f %% der Samples" % clip_pct)
print("  DC-Offset     : %7.3f %%" % dc)
print("  Kanal L/R     : %6.1f / %6.1f dBFS" % (db(rms(L)), db(rms(R))))
print()
if snr >= 45:
    print("Einordnung: SNR sehr gut (>= 45 dB)")
elif snr >= 30:
    print("Einordnung: SNR gut (30-45 dB)")
elif snr >= 20:
    print("Einordnung: SNR ausreichend (20-30 dB) - Stoergeraeuschunterdrueckung sinnvoll")
else:
    print("Einordnung: SNR schwach (< 20 dB) - Umgebung/Mikrofonabstand pruefen")
if peak_db > -3:
    print("Hinweis: Peak > -3 dBFS -> Pegel senken (Clipping-Gefahr)")
gain = -18.0 - db(speech)
if gain > 3:
    print("Empfehlung: Pegel um ca. %+.0f dB anheben (Ziel ~ -18 dBFS Sprache)" % gain)
elif gain < -3:
    print("Empfehlung: Pegel um ca. %+.0f dB senken (Ziel ~ -18 dBFS Sprache)" % gain)
else:
    print("Empfehlung: Sprachpegel im Zielbereich (~ -18 dBFS)")
print("Hinweis: SNR ist weitgehend pegelunabhaengig - bei lautem Rauschboden")
print("hilft nur Umgebung/Abstand, nicht die Verstaerkung.")
print()
print("Hinweis: P10/P90 sind robuste Frame-Pegel (20 ms); Raum-/Lueftergeraeusche")
print("stecken im Rauschboden. Werte sind umgebungsabhaengig, nicht absolut.")
PYEOF
  '';

  # Update + Build testen, OHNE bei Fehlern einen kaputten flake.lock zu hinterlassen.
  # Erfolg: neuer Lock bleibt stehen. Fehler: alter Lock wird restauriert.
  nixCheck = pkgs.writeShellScriptBin "nix-check" ''
    set -u
    repo=/etc/nixos
    host=$(hostname)
    trace=""
    if [ "''${1:-}" = "--trace" ]; then trace="--show-trace"; fi

    backup=$(mktemp)
    trap 'rm -f "$backup"' EXIT
    cp "$repo/flake.lock" "$backup"

    np_path() { nix eval --impure --raw --expr '(builtins.getFlake "/etc/nixos").inputs.nixpkgs.outPath' 2>/dev/null || true; }
    old_np=$(np_path)

    echo "== nix flake update =="
    if ! (cd "$repo" && nix flake update); then
      cp "$backup" "$repo/flake.lock"
      echo "nix-check: flake update fehlgeschlagen - Lock unveraendert."
      exit 1
    fi

    # Ankuendigung, die nixpkgs bei unstable nicht liefert: was wurde neu entfernt/umbenannt?
    new_np=$(np_path)
    if [ -n "$old_np" ] && [ -n "$new_np" ] && [ "$old_np" != "$new_np" ] \
       && [ -f "$old_np/pkgs/top-level/aliases.nix" ] && [ -f "$new_np/pkgs/top-level/aliases.nix" ]; then
      echo
      echo "== nixpkgs: neu entfernt/umbenannt =="
      diff -U0 "$old_np/pkgs/top-level/aliases.nix" "$new_np/pkgs/top-level/aliases.nix" 2>/dev/null \
        | grep -E '^\+.*= *(throw|warnAlias)' \
        | sed 's/^+ *//' | head -25 || true
    fi

    echo "== nixos-rebuild build ($host) =="
    if ! (cd "$repo" && nixos-rebuild build --flake ".#$host" $trace); then
      cp "$backup" "$repo/flake.lock"
      echo
      echo "nix-check: BUILD FEHLGESCHLAGEN."
      echo "flake.lock wurde auf den letzten Stand zurueckgesetzt; das System bleibt unangetastet."
      echo "Vollstaendiger Trace:  nix-check --trace"
      exit 1
    fi

    echo
    echo "== Wichtige Paket-Aenderungen (direkt gewaehlt, nur Versionswechsel) =="
    diff_out=$(nvd diff -s /run/current-system "$repo/result" 2>/dev/null || true)
    ver_lines=$(printf '%s\n' "$diff_out" | grep -E '^\[(U|A|R)' || true)
    if [ -n "$ver_lines" ]; then
      printf '%s\n' "$ver_lines"
    else
      echo "(keine Versionswechsel)"
    fi
    rebuilds=$(printf '%s\n' "$diff_out" | grep -cE '^\[C' || true)
    if [ "''${rebuilds:-0}" -gt 0 ]; then
      echo "($rebuilds weitere Rebuilds ohne Versionswechsel)"
    fi

    echo
    ${nixRebootCheck}/bin/nix-reboot-check "$repo/result"
    echo
    echo "nix-check: OK - Lock behalten. Switch mit: nix-switch"
  '';
in
{
  environment.systemPackages = with pkgs; [
    iw
    jq
    ookla-speedtest
    scx.full
  ] ++ [ nixCheck nixRebootCheck nixosUpdate audioRate micCheck ];

  programs.fish.shellAliases = {

    # System & Update (hostname wird per Fish-Funktion dynamisch aufgelöst)
    nix-search = "nix search nixpkgs";
    # nix-check ist ein eigenes Skript (siehe nixCheck oben) - restauriert den Lock bei Fehlern.
    nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#(hostname) && nix-reboot-check";
    nix-update = "pushd /etc/nixos && nix flake update && sudo nixos-rebuild switch --flake .#(hostname) && popd";
    # Reparatur-Sync: Inputs mit aktualisieren, damit kein Downgrade auf einen
    # alten Lock passiert, wenn der letzte Push schon laenger her ist
    # (bewusste Entscheidung -- nicht entfernen).
    nix-sync   = "pushd /etc/nixos && git reset --hard origin/main && git pull && nix flake update && sudo nixos-rebuild switch --flake .#(hostname) && nix-reboot-check && popd";
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
