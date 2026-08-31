#!/usr/bin/env python3
# GameDAC-Knacken-Fix (Titelwechsel): ASM-Filter-Ketten mit
# "node.pause-on-idle = false" erzeugen, damit die HeSuVi/Sonar-Convolution
# beim Stream-Neustart nicht in "idle" faellt und ihren Zustand behaelt
# (kein Transient/Knacken am Liedanfang). Wird im postPatch von
# arctis-sound-manager auf sonar_to_pipewire.py angewendet.
#
# WICHTIG: nur OUTPUT-Ketten patchen. Die Micro-INPUT-Kette
# (sonar-micro-eq) darf pause-on-idle NICHT bekommen, sonst bricht das
# Mikrofon (Input-Kette muss bei Nichtnutzung suspendieren duerfen).
import re
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "src/arctis_sound_manager/sonar_to_pipewire.py"

lines = open(path).read().splitlines()
out = []
added = 0
for ln in lines:
    out.append(ln)
    m = re.match(r"^(\s*)node\.name\s*=\s*", ln)
    if m and "micro" not in ln:
        out.append(f"{m.group(1)}node.pause-on-idle = false")
        added += 1

open(path, "w").write("\n".join(out) + "\n")
print(f"asm-pause-on-idle: {added} Props-Bloecke gepatcht")

# Sicherheitsnetz: 0 Treffer = Upstream hat sonar_to_pipewire.py umgebaut.
# Build hart fehlschlagen lassen, damit ein ASM-Update den Fix nicht
# stillschweigend kippt (Knacken käme sonst ohne Meldung zurück).
if added == 0:
    raise SystemExit(
        "asm-pause-on-idle: KEINE node.name-Zeile gefunden — "
        "Patch passt nicht mehr zur ASM-Version; Skript anpassen!"
    )
