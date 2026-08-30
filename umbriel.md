# Umbriel – Version- & Feature-Tracking

Zweck: Die Umbriel-Entwicklung im Blick behalten, damit die Config nach jedem
nixpkgs-Update wieder auf den aktuellen Stand gebracht wird (dieses Build kennt
bereits dokumentierte Features noch nicht). Grundlagen siehe `memory.md` (Umbriel).

## Gepinnter Stand
- Paket: `umbriel-0-unstable-2026-08-25`
- Source-Rev: `af351dfa7564eaa0e73d215d057eb0b209cba057`
- Quelle: https://github.com/noctalia-dev/umbriel (main), nixpkgs-PR #555208
- Binaries aus `cache.nixos.org` (kein lokaler Build)

## WICHTIG – Namens-Instabilität
- Doku (main) dokumentiert Actions als `column-*` (z.B. `column-center`, `column-move-to-workspace`).
- Build 2026-08-25 nutzt `window-*` (`window-center`, `window-move-to-workspace`).
- Maßgeblich ist `umbriel msg --help` der LAUFENDEN Version, nicht die main-Doku.
  Gegenprobe: `umbriel validate`.

## Update-Ablauf („Config auf aktuellen Stand bringen")
1. `nix flake update nixpkgs`
2. Neue Version prüfen: `nix eval --raw nixpkgs#umbriel.version` (ggf. `... .src.rev`),
   Vergleich mit dem gepinnten Stand oben.
3. Feature-Tracker unten abhaken und Keys in beiden Hosts eintragen:
   `home/{mortiferus,backbone}/config/umbriel/` (gleiche Dateien, gleicher Stand).
4. `umbriel validate` → `config: ok`; danach `umbriel msg --help` gegen die Actions prüfen.
5. Test auf nex (Login-Neustart!), erst dann auf styx.

## Feature-Tracker (im Build 2026-08-25 NICHT vorhanden, in main dokumentiert)
| Config-Key | Zweck | Priorität |
|---|---|---|
| `input.keyboard.numlock_toggle` | Numlock beim Start AN (Benutzer will Standard-An) | HOCH – zuerst. Wert `true` setzen + nach Reboot testen (Numlock-State bleibt nur bis Reboot hardware-klebrig, kein Compositor-Eingriff nötig) |
| `keybinds.*.allow_when_locked` | Media-/Lautstärke-Keys auch im Lock nutzbar | MITTEL – optional (aktuell nur entsperrt) |
| `appearance.drag_opacity` | Fenster-Transparenz beim Drag | NIEDRIG – optional (aktuell Default) |
| `[animation]`-Sektion | Animations-Optionen | NIEDRIG – wir nutzen derzeit `appearance.animation_ms = 250`; falls Sektion kommt, Optionen vergleichen |
| `layout.scrolling.center_focused` | Scroll-Layout: Fokus-Zentrierung | NIEDRIG – optional |
| `layout.scrolling.expand_single_column` | Einzelspalte auf Strecken | NIEDRIG – optional |
| `layout.struts` (`[layout.struts]`) | Struts/Reservierung | NIEDRIG – optional (Noctalia-Bar/Dock regelt) |
| `workspaces.empty_above` | Leere Workspaces über dem aktuellen | NIEDRIG – optional |
| `input.touchpad.disable_on_external_mouse` | Touchpad bei Maus deaktivieren | IRRELEVANT – Touchpad ist systemweit deaktiviert |

## Zuletzt gecheckt
- **2026-08-31** (Set-up abgeschlossen, Wortlaut der Rules aus `docs/user/rules.md` @ af351dfa bestätigt): beide Hosts `umbriel validate` = `config: ok`, sauberer Start ohne Warning-Banner.
  - Umsetzungen auf Basis dieses Builds: **Blur global** über Catch-all `[[window_rule]] blur = true` (Merge-Semantik: jede Regel trägt Felder bei, spätere gewinnt pro Feld → Catch-all überschreibt kein workspace/vrr/floating); **VRR nur per Fenster** (`window_rule.vrr`, Werte `disabled|always|fullscreen`, override des Output-Policy wenn fokussiert); Opacity 0.95 für Discord/Steam/Legcord.
  - Erkenntnis Flackern: globales `output.vrr = "always"` flackerte auf Electron-Fenstern (Zen) → `disabled` + per-window Rules; Blur selbst verursachte kein Flackern.