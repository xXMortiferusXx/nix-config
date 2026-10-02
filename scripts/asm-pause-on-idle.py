#!/usr/bin/env python3
# GameDAC-Warmhalten-Fix: ASM-Filterketten mit "node.pause-on-idle = false"
# erzeugen, damit Sonar-EQ/Convolution bei Signalpausen nicht in "idle"
# fallen. Ohne das suspendet WirePlumber die Kette nach ein paar Sekunden
# Stille, und der Ton ist kurz weg, bis etwas sie wieder aufweckt.
# Wird im postPatch von arctis-sound-manager auf sonar_to_pipewire.py
# angewendet.
#
# WICHTIG - nur die INPUT-/Sink-Seite patchen (capture.props):
#   * Der Fork setzt pause-on-idle auf der PLAYBACK-Seite bereits selbst
#     (Platzhalter {_pause_on_idle_line}, gesteuert per channel != "output").
#     Wuerden wir dort ebenfalls einfuegen, entstuenden fuer Game/Media/Chat/
#     Aux DOPPELTE pause-on-idle-Zeilen im selben props-Block -> ungueltige
#     filter-chain-Config.
#   * Der "output"-Kanal ist bewusst ausgenommen (Headset darf ausgehen).
#   * Die Micro-INPUT-Kette (sonar-micro-eq) darf es NICHT bekommen, sonst
#     bricht das Mikrofon (Input-Kette muss suspendieren duerfen).
#
# Deshalb: nach einer node.name-Zeile nur einfuegen, wenn sie weder Micro
# noch eine Output-/Playback-Node referenziert.
import re
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "src/arctis_sound_manager/sonar_to_pipewire.py"

# Node-Namen (bzw. Format-Strings), die NICHT gepatcht werden duerfen.
#  - micro:           Input-Kette des Mikrofons
#  - effect_output:   EQ-Playback-Node      -> Fork setzt es selbst
#  - _out_node:       HeSuVi-Playback-Node  -> Fork setzt es selbst
#  - effect_input.:   wird per replace() zur effect_output-Node (Playback)
SKIP_MARKERS = ("micro", "effect_output", "_out_node")

lines = open(path).read().splitlines()
out = []
added = 0
for ln in lines:
    out.append(ln)
    m = re.match(r"^(\s*)node\.name\s*=\s*", ln)
    if not m:
        continue
    if any(marker in ln for marker in SKIP_MARKERS):
        continue
    # Sicherheitsnetz: falls die naechste Zeile schon pause-on-idle setzt
    # (Upstream hat nachgezogen), nicht doppelt einfuegen.
    idx = len(out)
    nxt = lines[idx] if idx < len(lines) else ""
    if "pause-on-idle" in nxt:
        continue
    out.append(f"{m.group(1)}node.pause-on-idle = false")
    added += 1

open(path, "w").write("\n".join(out) + "\n")
print(f"asm-pause-on-idle: {added} capture/Sink-Ketten gepatcht")

# Sicherheitsnetz: 0 Treffer = Upstream hat sonar_to_pipewire.py umgebaut.
# Build hart fehlschlagen lassen, damit ein ASM-Update den Fix nicht
# stillschweigend kippt (Ton-Aussetzer kaemen sonst ohne Meldung zurueck).
if added == 0:
    raise SystemExit(
        "asm-pause-on-idle: KEINE passende node.name-Zeile gefunden — "
        "Patch passt nicht mehr zur ASM-Version; Skript anpassen!"
    )
