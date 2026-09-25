# ALC287 Mic-Gain & Lautstärke-Fix — CachyOS (Arch) / WirePlumber

> Folgenden Text komplett in opencode einfügen. Am besten im Home-Verzeichnis
> des Users (nicht in /etc/nixos!) ausführen, da sonst nur Lese-/Schreibrechte
> für den Home-Bereich angenommen werden — für die sudo-Schritte fragt der
> Freund seine Passphrase ab.

---

Bitte hilf mir, das Problem „sehr leises Mikro + Ausgabe fällt auf ~6 % zurück"
auf meinem CachyOS-Laptop endgültig zu beheben.

**Hintergrund:** Ich nutze ein rein passives analoges Headset (MMX 330 Pro,
TRRS) am Realtek ALC287-Codec. Problem 1: Das Mikro ist extrem leise, weil der
Codec-Preamp schwach ist und die Vorverstärkungsstufen anfangs nicht besetzt
sind. Problem 2: Nach Route-Änderungen oder Neustarts sinkt die Lautstärke des
Ausgangs auf ca. 6 %, weil WirePlumber einen internen Default von
`device.routes.default-sink-volume = 0.064` gesetzt hat und gespeicherte
Routen/Volumes zurückspielt. Ich nutze **kein** ASM/Sonar — nur reines
PipeWire + WirePlumber.

**Wichtig:** Die Karten-(controlC-)Nummer kann variieren. Prüfe zuerst Schritt
1 und passe die Nummer im folgenden Code überall an, falls deine ALC287-Karte
nicht `controlC1` ist.

## Schritt 1 — Karte UND Codec-Chip identifizieren (erst gegenprüfen!)

Führe zuerst aus und zeige mir die Ausgaben:

```bash
cat /proc/asound/cards
cat /proc/asound/card*/codec#0 | grep -E "^Codec:"
amixer -c 1 scontrols
```

**Prüfe, was da wirklich drinsteckt:** Ich weiß nicht sicher, welcher
Realtek-Codec verbaut ist — es kann ein ALC287, ALC256, ALC295 o. Ä. sein.
Der folgende Fix heißt zwar „ALC287", funktioniert aber **für alle ALC-HDA-Codecs**
gleich (gleiches Schema `Capture` + `Mic Boost` + `Internal Mic Boost`).

Bestätige mir:
1. die Karten-Nummer des analogen (nicht HDMI/USB) Codecs — Beispiel unten geht
   von `controlC1` aus, passe den Index sonst in allen Schritten an;
2. ob die Control-Namen `Capture`, `Mic Boost`, `Internal Mic Boost` in
   `scontrols` auftauchen — falls anders benannt, passe die Skript-Zeilen an.

**Achtung:** Die konkreten dB-Werte (z. B. `source-volume 0.20 == Capture 47
== +18 dB`) habe ich empirisch an einem ALC287 nachgemessen. Auf anderen
ALC-Chips kann die Kennlinie leicht abweichen — der Pegel wird hier aber
nicht raten, sondern über eine Testaufnahme verifiziert und die Werte werden
so lange justiert, bis sie stimmen.

## Schritt 2 — Gain-Skript anlegen

Erstelle `/usr/local/bin/alc287-mic-gain.sh` mit folgendem Inhalt:

```bash
#!/bin/bash
set -eu
amixer -c 1 sset 'Capture' 47
amixer -c 1 sset 'Mic Boost' 1
amixer -c 1 sset 'Internal Mic Boost' 0
```

und mache es ausführbar:

```bash
sudo chmod +x /usr/local/bin/alc287-mic-gain.sh
sudo /usr/local/bin/alc287-mic-gain.sh
```

Falls die Control-Namen bei meinem Codec anders heißen (siehe `scontrols` oben),
passe sie an und weise mich darauf hin.

## Schritt 3 — Systemd-Service (Boot-Gain)

Erstelle `/etc/systemd/system/alc287-mic-gain.service`:

```ini
[Unit]
Description=Set ALC287 (Realtek) capture gain to 0 dB
After=sound.target
ConditionPathExists=/sys/class/sound/controlC1

[Service]
Type=oneshot
ExecStart=/usr/local/bin/alc287-mic-gain.sh

[Install]
WantedBy=sound.target multi-user.target
```

und aktiviere ihn:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now alc287-mic-gain.service
```

## Schritt 4 — Udev-Regel (Karten-Re-Add)

Erstelle `/etc/udev/rules.d/99-alc287-mic-gain.rules`:

```
SUBSYSTEM=="sound", KERNEL=="controlC1", ACTION=="add", RUN+="/usr/local/bin/alc287-mic-gain.sh"
```

und lade sie neu:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=sound
```

## Schritt 5 — WirePlumber-Conf (Volumen klemmmen / kein Route-Restore)

Erstelle `~/.config/wireplumber/wireplumber.conf.d/94-alc287-mic.conf`:

```
wireplumber.settings = {
  device.restore-routes = false
  device.routes.default-sink-volume = 1.0
  device.routes.default-source-volume = 0.20
}
```

Danach WirePlumber neu starten:

```bash
systemctl --user restart wireplumber pipewire pipewire-pulse
```

## Schritt 6 — Verifizieren

Zeige mir am Ende Ausgaben von:

```bash
amixer -c 1 sget 'Capture'
amixer -c 1 sget 'Mic Boost'
wpctl status
```

**Erwartung:** `Capture` auf 47, `Mic Boost` auf 1, Sink-Volume `1.00`,
Quell-Volume ca. `0.20`.

Ich mache dann zusätzlich eine Testaufnahme (ca. 10 s) vom Mikro. Wenn der
Pegel nicht gut ist (zu leise/tief ausgesteuert), **mess ich nach und passe
Capture/Mic Boost iterativ an**, bis die Aufnahme ~−4 dBFS Peak bei normaler
Sprache hat — die Werte oben sind Startwerte, kein Dogma.

---

**Einordnung der Werte (für mich zur Kontrolle):**
- `source-volume 0.20` entspricht am ALC287 exakt `Capture 47` = **+18 dB**
  (die Codec-Kennlinie ist nichtlinear: 0.05→Capture 0 = −17.25 dB, 0.10→23 =
  0 dB, 0.20→47 = +18 dB, 0.37→63 = +30 dB).
- `Mic Boost 1` = +10 dB analoge Vorstufe; `Internal Mic Boost` bleibt 0.
- `device.restore-routes = false` verhindert, dass WirePlumber gespeicherte
  Routen/Volumes zurückspielt (Quelle des „volle Lautstärke geht verloren").
- `default-sink-volume = 1.0` ersetzt den WP-Bug-Default von `0.064` (~6 %).
- Hinweis Discord: Falls es dort rauscht/verzerrt, Echo-/Rauschunterdrückung
  bzw. automatische Verstärkung ausschalten — Discord verstärkt sonst doppelt.