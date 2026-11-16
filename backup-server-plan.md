# Backup- & Server-Plan (Stand 2026-11-16)

Ziel: **Alle Hosts automatisch und wiederherstellbar sichern**, ohne dass die
Nutzer etwas tun müssen – und ohne dass ein Host (oder ein Familienmitglied)
die Backups zerstören kann. Optional zusätzlich ein Build-/Cache-Server, damit
Kernel- und Paket-Builds nachts laufen und nicht auf dem Notebook.

Status: **Planung.** Es ist noch nichts davon umgesetzt. Offen ist vor allem die
Anbieterwahl (siehe „Anbieter-Vergleich").

---

## 1. Architektur

```
nex / styx / lion-pc / benny
   │  täglicher systemd-Timer, restic, clientseitig verschlüsselt
   │  Zugang: nur schreiben + lesen, KEIN löschen
   ▼
Object Storage (B2 oder gleichwertig)         ← Primärziel
   ▲
   │  Prune/Retention + `restic check` (Master-Key)
   └── nex (zentral, monatlich)

Optional zweite Kopie: Hetzner Storage Box, ebenfalls zentral von nex beschrieben.
```

**Schutzmodell (wichtigster Punkt):**

- Jeder Host bekommt einen **eigenen Application-Key ohne `deleteFiles`**.
  Damit kann selbst `root` auf dem Host die Remote-Backups nicht löschen –
  nur neue Daten schreiben. Schützt gegen Fehlbedienung und Ransomware.
- **Prune** (Löschen alter Snapshots) läuft nur zentral auf nex mit dem
  Master-Key, nie auf den gesicherten Hosts.
- Jedes Host-Repo ist getrennt (`/backups/<host>` bzw. eigener Bucket/Prefix),
  damit ein kompromittierter Host nicht an die Backups der anderen kommt.
- Verschlüsselung clientseitig (restic). Der Anbieter sieht nur Chiffrat.

**Restore:**

- `restore-home <host>` (Teil der Flake-Config, nach jeder Installation sofort
  vorhanden) holt `/home/<user>` + ausgewählte `/var/lib`-Pfade, setzt die
  Rechte und prüft anschließend Keyring, `~/.ssh` und Steam-Daten.
- `install.sh` bekommt einen optionalen Block nach `nixos-install`:
  „Backup wiederherstellen? [j/N]" → Repo + Passwort abfragen → nach `/mnt`
  restoren → `chown` auf UID/GID des Zielsystems.
- NixOS-Installer selbst kann **kein** Backup einspielen (kennt Repo/Passwort
  nicht) – deshalb der Skript-Block.

**Passwörter:**

- restic-Repo-Passwort ist **nicht zurücksetzbar** (kein „Passwort vergessen").
  Ohne Passwort = Backups verloren.
- Deshalb: eine **Papierkopie** (Repo-URL + Passwort pro Host) im Schrank,
  optional zweite Kopie außerhalb. Kein Passwortmanager nötig.
- Auf den Hosts liegt für den Timer nur eine root-only-Datei
  (`/var/lib/restic/pass`, `chmod 600`).
- Login-Passwort ≠ restic-Passwort: Ein Login-Reset (z. B. bei benny) berührt
  die Backups nicht.

---

## 2. Entscheidungen (fest)

| Thema | Entscheidung |
|---|---|
| Tool | **restic** (ein Binary, S3 + SFTP, clientseitige Verschlüsselung) |
| Automatisierung | systemd-Timer pro Host, täglich, `Persistent=true` |
| Host-Zugang | eigener Key, **ohne Löschrecht** |
| Prune | zentral auf nex, monatlich, Master-Key |
| Prüfung | `restic check --read-data-subset=5%`, monatlich auf nex |
| Benachrichtigung | nur bei Fehlschlag (kein tägliches Rauschen) |
| Restore | `restore-home` + `install.sh`-Block, Passwort von Papier |
| sudo | **unverändert**: benny ohne Passwort, lion mit Passwort, nex ohne |
| lion-pc | bleibt wie er ist (`wheelNeedsPassword = mkForce true`) |
| Ausgeschlossen | `/nix/store`, `/gaming`, `~/.cache`, `steamapps/common`, `steamapps/workshop`, `steamapps/downloading`, `shadercache`, `depotcache`, Trash, Container-Images |
| Gesichert | `/home/<user>`, `/etc/nixos`, `/var/lib/bluetooth`, `~/.local/share/keyrings`, `/var/lib/flatpak` (falls genutzt), `/etc/NetworkManager/system-connections` |
| Savegames | **`steamapps/compatdata` und `Steam/userdata` bleiben drin** (Proton-Prefixes enthalten die Spielstände), ebenso Wine-Prefixes (`vinegar`, `xodus-nexus`, `umu`, `lutris`) |
| Bilder | **ja** – inkl. `~/Bilder/Wallpaper` (~311 MB), damit Umbriel-Hintergründe nach einer Neuinstallation wieder da sind. Nicht ins öffentliche Repo (Verbreitung), nur ins verschlüsselte Backup |
| Musik | **nein** – bewusst ausgelassen (rechtliche Unsicherheit, jederzeit neu beschaffbar) |
| Browser | **ja, komplett.** Firefox-Profil liegt **nicht** in `~/.mozilla`, sondern unter `~/.config/mozilla/firefox/<profil>` (XDG), Thunderbird unter `~/.config/thunderbird`, Chromium unter `~/.config/chromium`. Zusätzlich `~/.local/share/keyrings` (nötig für Chromium-Passwörter und falls Firefox den System-Keyring nutzt). Firefox-Passwörter selbst liegen profilgebunden in `key4.db` + `logins.db`. Ausgeschlossen: `~/.cache` (1,1 GB Firefox-Cache), `gmp-widevinecdm`, `datareporting`, `security_state`, Telemetrie |
| Keyring | **aktiv** (`services.gnome.gnome-keyring`, Portal `Secret` → gnome-keyring). Dateien im Backup; nach Restore **gleiches Login-Passwort** nötig, sonst bleibt er zu |
| Passkeys | Hardware-Passkeys (FIDO2-Stick) sind **nicht** sicherbar → zweiten Key registrieren (siehe `passkey.md`). Software-Passkeys stecken in Firefox-Profil bzw. Chromium-Profil + Keyring und sind damit abgedeckt |

**Nicht** umgesetzt wird: Wheel-Entzug für benny (erwachsen, soll lernen –
Schutz kommt von der Backup-Seite) und NOPASSWD für `nixos-rebuild` auf lion
(wäre faktisch root, weil `/etc/nixos` dem User gehört).

---

## 3. Größenordnung (gemessen auf nex, 2026-11-16)

| Posten | Größe | Anmerkung |
|---|---|---|
| `/home/mortiferus` komplett | 71 GB | inkl. Spiele/Testdateien |
| ohne Caches/Steam | 19 GB | realistischer Backup-Satz |
| `Steam/steamapps/common` | 2,5 GB | ausgeschlossen (Spieldaten) |
| `Steam/steamapps/compatdata` | 1,2 GB | **gesichert** (Saves) |
| `Steam/userdata` | 4,6 MB | **gesichert** |
| `~/.config/chromium` | 98 MB | gesichert (sekundär); Passwörter brauchen zusätzlich `~/.local/share/keyrings` |
| `~/.config/mozilla/firefox/<profil>` | **432 MB** | **gesichert** (Hauptbrowser); `storage` 268 MB, `extensions` 39 MB, `places.sqlite` 10 MB; ohne DRM/Telemetrie ~370 MB |
| `~/.config/thunderbird` | 16 MB | gesichert (E-Mail-Konten/lokale Mails) |
| Wine-Prefixes (`vinegar`/`xodus`/`umu`/`lutris`) | ~6,8 GB | **gesichert** (Saves) |
| `/etc/nixos` inkl. `.git` | 220 MB (davon 172 MB `.git`) | gesichert, Historie ist wertvoll |
| Bluetooth + NM-Profile | < 1 MB | gesichert |

**Schätzung gesamt:** 25–40 GB für alle Hosts, mit Retention/Dedup 50–80 GB.
Kosten bei B2 damit **< 1 €/Monat**; die 1-TB-Storage-Box ist überdimensioniert,
aber als zweite Kopie für 3,81 € vertretbar.

Der große Speicherbedarf entsteht nur beim **Build-Cache** (Nix-Store, hunderte
GB) – nicht bei den Daten.

---

## 4. Anbieter-Vergleich (geprüft 2026-11-16)

### Backup-Ziel (Object Storage / Storage)

| Anbieter | Preis | Privatkunden | Object Lock | Anmerkung |
|---|---|---|---|---|
| **Backblaze B2** | **6,95 $/TB/Monat** (0,00695 $/GB) | ja | ja | 3× Egress frei, danach 0,01 $/GB; API-Calls frei (Class D minimal); EU-Region Amsterdam |
| **Hetzner Storage Box BX11** | **3,81 €/Monat für 1 TB brutto** | **ja** | nein | interner Traffic inklusive, Snapshots, Borg/restic über SFTP/rsync; BX21 = 5 TB / 12,97 € |
| IONOS Cloud Object Storage | **7,00 €/TB** (0,007 €/GB/30 Tage) | **nein** | ja | **B2B-only** („ausschließlich Gewerbetreibende") → für Privatprojekt ausgeschlossen; Datenübertragung laut Fußnote extra |
| Scaleway Object Storage | ~14,6 €/TB (Standard), Glacier ~2 €/TB | ja | teilweise | Preise nicht live verifiziert (JS-Seite) |
| OVH Object Storage | ~12 €/TB (Standard), Archive günstiger | ja | teilweise | Preise nicht live verifiziert; Mindestaufbewahrung bei Cold-Klassen |
| **Contabo Object Storage** | **ab 2,49 €/Monat** (Paketpreis, unbegrenzter Transfer) | ja (nur für bestehende Contabo-Kunden) | ja („Object-Locking") | **deutsches RZ**, S3-kompatibel, Versionierung, 3 Regionen (EU/US/SG), 3-fach repliziert; Rechte pro Key unklar → Schutz über Object Lock |
| Wasabi (Frankfurt) | ~6,99 $/TB | ja | – | deutscher Standort, US-Firma; 90 Tage Mindestaufbewahrung → Prune unpraktisch |

**Tendenz:** B2 als Primärziel (Object Lock + Rechte-Modell für Write-only-Keys),
Storage Box optional als zweite Kopie zentral von nex.

### Build-/Cache-Server (optional, noch nicht entschieden)

Gemessene Ausgangslage: nex = Ryzen 5 5600H (6C/12T), NixOS-Kernel-Build dort
~6–10 min. Ein Nachtfenster reicht also auch für langsamere Hardware.

| Angebot | CPU | RAM | Platten | Preis | Bemerkung |
|---|---|---|---|---|---|
| Nocix E3-1270v2 | 4C/8T Ivy | 16 GB | 480 GB SSD + 4 TB | **$45** | beste Passung: SSD für Cache, HDD für Backups, 1 Gbit unmetered |
| Nocix E3-1230v2 | 4C/8T Ivy | 32 GB | 4 TB HDD | $45 | mehr RAM, keine SSD |
| Nocix Dual Xeon 5520 | 8C/16T, 2,26 GHz | 64 GB | 240 GB SSD + 4 TB | **$35** | billig, aber langsame Kerne |
| Nocix Dual Xeon E5-2670 | 16C/32T | 96 GB | 960 GB SSD | $59 | schnellster Kompromiss fürs Bauen |
| Nocix Ryzen 9 3900X (custom) | 12C/24T Zen2 | 32 GB | konfigurierbar | $84 | wenn Build-Zeit wirklich zählt |
| Server4you Skylake i7-6700 | 4C/8T | 32 GB | 2× 1 TB **HDD** | 29,99 € | EU (Straßburg), aber HDD-only → Cache/Store langsam |
| Server4you E-2146G | 6C/12T | 32 GB | prüfen | 34,99 € | mehr Kerne, Storage unklar |
| Server4you E-2286G + NVMe | 6C/12T 4,0 GHz | 64 GB | NVMe | 109,99 € | beste Option dort, aber 3,7× Preis |
| Hetzner Dedicated | – | – | – | **ab ~59 €** | Preise 2026 deutlich gestiegen |
| Hetzner Serverbörse | – | – | – | **ab ~78 €** | Auktion, aktuell kein Preisvorteil |

**Tendenz:** Entweder Nocix E3-1270v2 ($45) oder Dual Xeon 5520 ($35) als
Cache+Backup-Blech, oder gar kein Dedicated: Builds laufen weiter auf nex,
Backups gehen direkt in den Object Storage (dann ~7–12 €/Monat gesamt).

**Wichtig bei US-Anbietern:** Latenz 110–130 ms (irrelevant für Backups,
spürbar für SSH), US-Jurisdiktion (bei verschlüsselten Backups unkritisch),
alte Hardware (SMART nach Erstboot prüfen, `smartd` aktivieren), kein RAID in
den Instant-Angeboten.

---

## 5. Offene Punkte

1. **Anbieter-Entscheidung** Backup-Ziel: B2 (Primär) + Storage Box (Sekundär)?
2. **Zweite Kopie** ja/nein und wo (anderer Anbieter/Jurisdiktion empfohlen).
   - Vorgesehene Variante: **zentral von nex** (`restic copy`) → nur ein Credential fürs
     Zweitziel, die anderen Hosts haben keinen Zugang. Kandidat: Hetzner Storage Box
     (Sub-Account nur für nex, Snapshots als Löschschutz).
   - Dezentral (jeder Host schreibt selbst) nur, wenn die zweite Kopie unabhängig vom
     nex-Lauf aktuell sein muss – kostet dann pro Host ein eigenes Credential.
3. **Build-Server** ja/nein; falls ja: Nocix E3-1270v2 ($45) oder 5520 ($35).
4. **B2-Keys** pro Host anlegen (Capabilities: `listFiles`, `readFiles`,
   `writeFiles`, **kein** `deleteFiles`), Master-Key nur auf nex.
5. Retention-Werte festlegen (Vorschlag: `--keep-daily 7 --keep-weekly 4
   --keep-monthly 12`).
6. Was genau gesichert wird, pro Host final festzurren (benny/lion haben
   andere Daten als nex).
7. Papier-Sheet erstellen (Repo-URLs + Passwörter) und ablegen.

## 6. Umsetzung (wenn grün)

- [ ] `services.restic.backups` für nex / styx / lion-pc / benny
- [ ] B2-Buckets + Application-Keys (write-only) pro Host
- [ ] `restore-home`-Skript + `RECOVERY.md`
- [ ] Restore-Block in `install.sh` (nach `nixos-install`)
- [ ] Prune- + Check-Timer auf nex (mit Master-Key)
- [ ] Fehlschlag-Benachrichtigung (ntfy/Matrix/Mail)
- [ ] Papier-Sheet mit Repo-Passwörtern
- [ ] Testrestore einmal komplett durchspielen (z. B. lion-pc in `/tmp`)

## 7. Referenzen

- restic: <https://restic.readthedocs.io>
- NixOS restic-Modul: `services.restic.backups` (Optionen: `paths`, `exclude`,
  `passwordFile`, `pruneOpts`, `timerConfig`, `initialize`)
- Backblaze B2 Preise: <https://www.backblaze.com/cloud-storage/pricing>
- Hetzner Storage Box: <https://www.hetzner.com/de/storage/storage-box/>
- Nocix Angebote: <https://www.nocix.net/dedicated/#instant>
- Server4you: <https://server4you.com/de/dedicated-server/>
