# Umbriel – Version- & Feature-Tracking

Zweck: Die Umbriel-Entwicklung im Blick behalten, damit die Config nach jedem
Update wieder auf den aktuellen Stand gebracht wird (die Doku/Features sind dem
Build oft voraus). Grundlagen siehe `memory.md` (Umbriel).

## Gepinnter Stand
- Quelle: **direkt vom Umbriel-Flake** (`git+https://github.com/noctalia-dev/umbriel`, main)
  statt nixpkgs — damit Fixes/Features zeitnah ankommen. Overlay in
  `modules/desktop/umbriel.nix` ersetzt `pkgs.umbriel`.
- Aktuelle Rev: `786c237c516af2fc9befbc72e5e303979c82b647` (2026-09-04), Version `0.1.0`
- Update via `nix flake update` (zieht main neu); danach normaler `switch`.
- **Lokaler Build** (kein Binär-Cache für die Flake-Rev).

## Wann zurück zu nixpkgs?
- Solange auf dem Flake bleiben, bis nixpkgs den Fix-/Feature-Stand eingeholt hat
  (`nix eval nixpkgs#umbriel.src.rev` ≥ Flake-Rev bzw. enthält Suspend/Resume-Fix #27,
  Numlock, `[animation]`) **und** die Entwicklung sich beruhigt hat (aktuell ~40 Commits/Tag;
  ein Tag-Release wäre das klarste Zeichen).
- Kosten Flake: lokaler Rust-Build (~Minuten) bei jedem Rev-Bump.
- Wechsel zurück: Flake-Input + Overlay (`modules/desktop/umbriel.nix`) raus, `nix eval nixpkgs#umbriel`
  prüfen, Config ggf. re-migrieren (falls nixpkgs-Rev anders steht).

## WICHTIG – Namens-Instabilität
- Ab Rev 2026-08-31 existieren **beide** Action-Familien: `window-*` (Fenster) UND
  `column-*` (Spalten). `workspace-set-layout` kann jetzt zusätzlich `master`.
- Maßgeblich ist `umbriel msg --help` der LAUFENDEN Version, nicht die main-Doku.
  Gegenprobe: `umbriel validate`.

## Update-Ablauf („Config auf aktuellen Stand bringen")
1. `nix flake update` (zieht main neu)
2. Neue Rev prüfen: `nix eval --raw '.#nixosConfigurations.nex.config.programs.umbriel.package.version'`
3. Config gegen das NEUE Binary validieren (vor dem Switch!):
   `nix build '.#nixosConfigurations.nex.config.programs.umbriel.package' --no-link` →
   `<out>/bin/umbriel validate -c <config>` (beide Hosts).
4. Keys/Actions unten abhaken und ggf. in beiden Hosts eintragen:
   `home/{mortiferus,backbone}/config/umbriel/` (gleiche Dateien, gleicher Stand).
5. `switch` + **Login-Neustart** auf nex, erst dann styx.

## Feature-Tracker (Stand: Rev 786c237 / 2026-09-04)
| Config-Key | Zweck | Status |
|---|---|---|
| `input.keyboard.numlock_toggle` | Numlock beim Tastatur-Connect AN | **EINGEBAUT** (beide Hosts `true`, 2026-08-31) |
| `[animation]`-Sektion | Animations-Optionen (ersetzt `appearance.animation_ms`) | **MIGRIERT** → `cfg/animation.toml` (beide Hosts, 2026-08-31) |
| `appearance.drag_opacity` | Fenster-Transparenz beim Drag | **GESETZT** (`0.9` in `cfg/appearance.toml`, 2026-08-31) |
| `keybinds.*.allow_when_locked` | Keys auch im Lock nutzbar | **EINGESETZT** (Volume/Brightness/Mikro/Media-Tasten, beide Hosts, 2026-08-31) |
| `layout.scrolling.center_focused` | Scroll-Layout: Fokus-Zentrierung | verfügbar, nicht gesetzt |
| `layout.scrolling.expand_single_column` | Einzelspalte auf Strecken | verfügbar, nicht gesetzt |
| `layout.struts` | Struts/Reservierung | verfügbar, nicht gesetzt (Noctalia regelt) |
| `workspaces.empty_above` | Leere Workspaces über dem aktuellen | verfügbar, nicht gesetzt |
| `input.touchpad.disable_on_external_mouse` | Touchpad bei Maus deaktivieren | IRRELEVANT (Touchpad systemweit aus) |
| `window-toggle-scratchpad` / `window-cycle-width-back` / `workspace-move-up/down` | neue Actions | **TEILWEISE EINGESETZT** (2026-08-31): `window-move-up/down` (Mod+CTRL+Pfeile), `window-cycle-width` (Mod+R); `window-toggle-scratchpad` u. `workspace-move-*` weiterhin ungebunden |
| `default_maximize_to_edges` (window_rule) | Fenster-Regel | verfügbar, nicht genutzt |
| `output.<NAME>.layout.scrolling.default_width_fraction` | per-Output-Startspaltenbreite überschreiben | verfügbar, nicht gesetzt (nur 1 Monitor) |

## Zuletzt gecheckt
- **2026-09-04** (Update auf Rev `786c237`): 45 Commits seit `06de3bfa`. **Ein Breaking Refactor**:
  `refactor(config)!` (`5a7cc8a2`) – alle Farb-Keys aus `[appearance]`/`[overview]` nach `[colors]` verschoben
  (`colors.border.*`, `colors.insert_hint`, `colors.backdrop`, `colors.shadow`, `colors.overview.*`).
  Alte Keys gelten jetzt als **unbekannt** (werden ignoriert, nur Warnung in `umbriel validate`).
  **Unser Config nicht betroffen**: `appearance.toml` setzt keine Farben, und `noctalia.toml` ist nicht
  in `[include]` gelistet → kein Fremd-Farb-Key möglich. **Visual nach Login-Pruefen** (Noctalia-Template muesste
  auf `[colors]` umgestellt sein, sonst Fallbacks). Sonstiges Neues: Default-`Mod+Q`=`window-close` (wir setzen
  die Bindung eh selbst, kein Handlungsbedarf); CLI `umbriel outputs --json`; perf `umbrielfx` (HDR-Buffer-
  Sharing + Output-LUT-Cache). Fixes: `allow empty regex match in window rules` (#65, betrifft Rules), Struts-
  Scrolling-Gaps (#91), Resize past neighbor minimum (#96), Floating-Resize-Animation (#102), Dialog-Stacking
  (#138), Cursor folgt verschobenen Fenstern (#134), uniform Corner-Rounding (#109), Clipboard legacy data-
  control (#104), `dbus-run-session`-Fallback im Start. **Lock bereits auf `06de3bfa`→`786c237`; Build/validate
  und Switch ausstehend (user macht das selbst).**
- **2026-09-02** (Update auf Rev `06de3bfa`): 17 Commits seit `e677dbbe`, davon **1 neuer Config-Key**:
  `output.<NAME>.layout.scrolling.default_width_fraction` (per-Output-Startspaltenbreite, `7597236`);
  Rest sind Fix/Perf/Refactor (Blur, umbrielfx, renderer, IPC). **Nicht übernommen** (1 Monitor).
  Lock ist bereits auf `06de3bfa`; Build/validate und Switch noch ausstehend.
- **2026-09-01** (Nacharbeit): aus dem Feature-Tracker übernommen — `appearance.drag_opacity = 0.9`;
  `keybinds.*.allow_when_locked` für Volume/Brightness/Mikro/Media-Tasten; neue Actions
  `window-move-up/down` (Mod+CTRL+Pfeile) u. `window-cycle-width` (Mod+R) gebunden.
- **2026-08-31** (Umstieg auf Flake-Rev `e677dbbe`): beide Hosts `validate` = `config: ok`
  gegen das neue Binary. Migriert: `animation_ms` → `[animation]`-Sektion; `numlock_toggle = true` eingebaut.
  - Umsetzungen (bestehen weiter): **Blur global** via Catch-all `[[window_rule]] blur = true`;
    **VRR nur per Fenster** (`window_rule.vrr`, output `disabled`); Opacity 0.95 für Discord/Steam/Legcord.
  - Bestätigt: alle früher fehlenden Feature-Keys (`drag_opacity`, `allow_when_locked`, `center_focused`,
    `expand_single_column`, `[layout.struts]`, `empty_above`, `disable_on_external_mouse`) sind jetzt valide.

## Bekannte Bugs
| Bug | Status | Fix |
|---|---|---|
| **Suspend/Resume: Fenster verlieren ihre Workspaces** (eDP-1 verschwindet beim Suspend → Fenster landen nach Wake „floating auf Workspace 1") | **BEHOBEN** | PR #27 „restore windows when every output goes away at once" — in Rev `e677dbbe` enthalten (aktiver Stand). Test nach Login-Neustart. |