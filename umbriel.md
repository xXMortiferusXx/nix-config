# Umbriel – Version- & Feature-Tracking

Zweck: Die Umbriel-Entwicklung im Blick behalten, damit die Config nach jedem
Update wieder auf den aktuellen Stand gebracht wird (die Doku/Features sind dem
Build oft voraus). Grundlagen siehe `memory.md` (Umbriel).

## Gepinnter Stand
- Quelle: **direkt vom Umbriel-Flake** (`git+https://github.com/noctalia-dev/umbriel`, main)
  statt nixpkgs — damit Fixes/Features zeitnah ankommen. Overlay in
  `modules/desktop/umbriel.nix` ersetzt `pkgs.umbriel`.
- Aktuelle Rev: `2952bbcbbb4669953abc67dd74f4cd9711dbce6b` (2026-10-31, revCount 1459), Version `0.1.0`
  (Lock per `nix flake update`; CLI `umbriel --version` = `0.1.0 (2952bbc)`;
  laufender Compositor braucht Login-Neustart, damit die neue Rev aktiv wird)
- Update via `nix flake update` (zieht main neu); danach normaler `switch`.
- **Lokaler Build** (kein Binär-Cache für die Flake-Rev).

## Wann zurück zu nixpkgs?
- Solange auf dem Flake bleiben, bis nixpkgs den Fix-/Feature-Stand eingeholt hat
  (`nix eval nixpkgs#umbriel.src.rev` ≥ Flake-Rev bzw. enthält Suspend/Resume-Fix #27,
  Numlock, `[animation]`, named scratchpads) **und** die Entwicklung sich beruhigt hat
  (Stand 2026-10-08: 33 Commits in 2 Tagen ≈ 16/Tag — weiterhin aktiv; ein Tag-Release
  wäre das klarste Zeichen).
- Kosten Flake: lokaler C++-Build (~Minuten) bei jedem Rev-Bump.
- Wechsel zurück: Flake-Input + Overlay (`modules/desktop/umbriel.nix`) raus, `nix eval nixpkgs#umbriel`
  prüfen, Config ggf. re-migrieren (falls nixpkgs-Rev anders steht).

## WICHTIG – Namens-Instabilität
- Ab Rev 2026-08-31 existieren **beide** Action-Familien: `window-*` (Fenster) UND
  `column-*` (Spalten). `workspace-set-layout` kann jetzt zusätzlich `master`.
- Ab Rev 2026-09-07: Scratchpad-Actions brauchen `[<scratchpad>]` Suffix (z.B.
  `scratchpad-toggle:default`). Bare Actions ohne Argument greifen auf den impliciten
  `"default"` Scratchpad.
- Ab Rev `4c89178` (2026-10-06): **CLI-Umbenennung** — `umbriel validate` wurde zu
  `umbriel config validate`, neu `umbriel config schema [--json]`. Das alte `validate`
  existiert nicht mehr (kein Alias).
- Ab Rev `2952bbc` (2026-10-31): **Breaking** — IPC-Actions nutzen **Wort-Argumente**
  (`e8ab5b00`): `name arg1 arg2` statt `name:arg`. Alte `:`-Bindings werden ignoriert
  („unknown action"). Beispiele: `workspace-switch 3`, `spawn noctalia msg ...`,
  `scratchpad-toggle default`, `session-quit skip-confirmation`, `workspace-set-layout toggle`.
- Maßgeblich ist `umbriel msg --help` der LAUFENDEN Version, nicht die main-Doku.
  Gegenprobe: `umbriel config validate`.

## Update-Ablauf („Config auf aktuellen Stand bringen")
1. `nix flake update` (zieht main neu)
2. Neue Rev prüfen: `nix eval --raw '.#nixosConfigurations.nex.config.programs.umbriel.package.version'`
3. Config gegen das NEUE Binary validieren (vor dem Switch!):
   `nix build '.#nixosConfigurations.nex.config.programs.umbriel.package' --no-link` →
   `<out>/bin/umbriel config validate -c <config>` (alle Hosts).
4. Keys/Actions unten abhaken und ggf. in allen Hosts eintragen:
   `home/{mortiferus,backbone,lion}/config/umbriel/` (gleiche Dateien, gleicher Stand).
   **Immer alle 3 Hosts pruefen** – lion ist aktiver im Einsatz als backbone und wird
   ueber `nix-sync` auf demselben Stand gehalten.
5. `switch` + **Login-Neustart** auf nex, erst dann styx/lion.

## Feature-Tracker (Stand: Rev b70b6fa / 2026-10-20)
| Config-Key | Zweck | Status |
|---|---|---|
| `input.keyboard.numlock_toggle` | Numlock beim Tastatur-Connect AN | **EINGEBAUT** (alle Hosts `true`, 2026-08-31) |
| `[animation]`-Sektion | Animations-Optionen (ersetzt `appearance.animation_ms`) | **MIGRIERT** → `cfg/animation.toml` (alle Hosts, 2026-08-31) |
| `appearance.drag_opacity` | Fenster-Transparenz beim Drag | **GESETZT** (`0.9` in `cfg/appearance.toml`, 2026-08-31) |
| `keybinds.*.allow_when_locked` | Keys auch im Lock nutzbar | **EINGESETZT** (Volume/Brightness/Mikro/Media-Tasten, alle Hosts, 2026-08-31) |
| `layout.scrolling.center_focused` | Scroll-Layout: Fokus-Zentrierung (jetzt String: `"never"`, `"always"`, `"on_overflow"`) | verfügbar, nicht gesetzt (Default `"never"` passt) |
| `layout.scrolling.expand_single_column` | Einzelspalte auf Strecken | **ENTFERNT** (Rev `a588733d`), ersetzt durch `match.is_alone` Window-Rule — nicht genutzt |
| `layout.struts` | Struts/Reservierung | verfügbar, nicht gesetzt (Noctalia regelt) |
| `workspaces.empty_above` | Leere Workspaces über dem aktuellen | verfügbar, nicht gesetzt |
| `input.touchpad.disable_on_external_mouse` | Touchpad bei Maus deaktivieren | IRRELEVANT (Touchpad systemweit aus) |
| `match.is_alone` (window_rule) | Fenster-Regel: matched wenn einzige geteilte Spalte auf Workspace | verfügbar, nicht genutzt |
| `default_scratchpad` (window_rule) | Fenster automatisch in Scratchpad stecken beim Öffnen | verfügbar, nicht genutzt |
| Named Workspaces in `default_workspace` | String-Workspace-Targets (`"CHAT"`) neben Integer | verfügbar, nutzen Integer (bevorzugt) |
| Scratchpad-Actions: `[<scratchpad>]` | Scratchpads global + named (statt per-output) | **MIGRIERT** (2026-09-09): alle 3 Hosts `:default`_suffix hinzugefügt |
| `default_maximize_to_edges` (window_rule) | Fenster-Regel | verfügbar, nicht genutzt |
| `output.<NAME>.layout.scrolling.default_extent_fraction` | per-Output-Startspaltenbreite überschreiben | verfügbar, nicht gesetzt (nur 1 Monitor) |
| `curve = "spring:<damping>,<stiffness>"` (z.B. `"spring:1,900"`, unter `animation.*`) | Spring-Physik statt zeitbasiert; Springs leiten Dauer selbst ab (`duration_ms` gilt dann nur für zeitbasierte Kurven). **Syntax gewechselt** (2026-09-26): die frühere `curve = "spring"` + `spring = { damping, stiffness }`-Tabelle wurde durch den Inline-String + Namens-Registry `[animation.springs]` / `[animation.beziers]` ersetzt | verfügbar, nicht genutzt (easeout/snappy+duration_ms reicht) |
| `animation.*.shader` (Custom-GLSL) | Fragment-Shader pro Event (`reveal.glsl`/`squash.glsl` werden mitgeliefert) | verfügbar, nicht genutzt |
| `animation.*.style = "popin"/"zoom"/"slide"/"fade"/"none"` | Öffnungs-/Schließ-Stil für `windows_in`/`windows_out` (popin + `scale`) | verfügbar, genutzt (popin/fade in `cfg/animation.toml`) |
| `appearance.opaque_fullscreen` | `false` lässt Fullscreen-Fenster Window-Rule-`opacity`/Blur respektieren (statt Backdrop) | verfügbar, nicht gesetzt (Default `true` passt) |
| `output.<NAME>.bit_depth` | 10-bit-SDR-Rendering (`8`/`10`, #172) | **GESETZT** (`10` in allen `display.toml`, alle Hosts, 2026-09-26 — Fallback auf 8-bit bleibt) |
| `output.<NAME>.cyclic_workspaces` | Workspace-Schritt über die Enden des Inventars (#267) | **GESETZT** (`true` in allen `display.toml`, alle Hosts, 2026-09-26) |
| `input.mouse/touchpad/tablet.left_handed` | Primär-/Sekundär-Tasten tauschen (#282) | verfügbar, nicht gesetzt |
| `input.touchpad.tap_button_map` | Tap-Zuordnung 1/2/3 Finger (`"left_right_middle"`/`"left_middle_right"`, #301) | verfügbar, nicht gesetzt |
| `border_color_focused/unfocused/outer` (window_rule) | Border-Farben pro Fenster überschreiben (#268) | verfügbar, nicht genutzt |
| `border_width`/`outer_border_width`/`corner_radius`/`shadow` (window_rule) | Deko-Override pro Fenster (#266, 4748217) | verfügbar, nicht genutzt |
| `window-move-to-workspace-silent:<ws>` (+`-next`/`-previous`) | Fenster still (ohne Fokus-Wechsel) verschieben (#273) | **GEBUNDEN** (`Mod+Shift+Ctrl+1..9`, alle Hosts, 2026-10-20) |
| `general.xwayland_native_resolution` | X11-Apps sehen physische Output-Auflösung → scharf bei Scale > 1 (2026-09-29) | IRRELEVANT (alle Outputs `scale = 1.0`); für Games auf skalierten Monitoren relevant |
| **Natives wlroots-Xwayland** | Umbriel startet Xwayland selbst; braucht `Xwayland` auf PATH statt `xwayland-satellite` (2026-09-29) | **ERLEDIGT**: `xwayland-satellite` aus `modules/desktop/umbriel.nix` entfernt; Flake-Wrapper + `programs.xwayland` liefern das Binary |
| `umbriel config validate` / `umbriel config schema [--json]` | CLI-Rename (`validate` → `config validate`), neues Schema-Listing (2026-09-27) | **DOKUMENTIERT** (umbriel.md/memory.md); kein Alias für altes `validate` |
| `[layout.tabs]` (`default_display`, `new_tab_position`, `wrap_focus`, `scroll_switches_tabs`, `middle_click_closes`) | Tab-Gruppen im Scrolling-/Master-Layout | verfügbar, nicht genutzt |
| `[appearance.tab_bar]` + `[colors.tab_bar]` | Aussehen/Farben der Tab-Leiste | verfügbar, nicht gesetzt |
| Tab-Actions (`column-toggle-tabbed`, `column-set-display:<normal\|tabbed>`, `column-focus-tab:<n>`, `column-focus-tab-next/previous`, `column-move-tab-next/previous`, `column-{toggle,hide,show}-tab-bar`) | Tab-Gruppen steuern | verfügbar, nicht gebunden |
| `match.app_id`/`title`/`xdg_tag` / `match.namespace` als **Array** | Mehrere Patterns pro Selektor (any-match) (#353) | verfügbar, nicht genutzt (Einzel-Patterns reichen) |
| `window_rule.default_column_display` | Spalte als `"tabbed"`/`"normal"` öffnen | verfügbar, nicht genutzt |
| `[effects]`-Engine (border/window/screen/cursor, Presets+Pools, `effect-*`-Actions) | GLSL-Effekt-Engine mit Pools/Runtime-Selection (#321/#336/#369) | verfügbar, nicht genutzt (Default off) |
| `window_rule.border_effect` / `window_effect` | Effekt pro Fenster ersetzen/abschalten | verfügbar, nicht genutzt |
| `window_rule` `default_focused` bei `default_scratchpad` | Scratchpad beim Öffnen gleich zeigen (#328) | verfügbar, nicht genutzt |
| `[[scratchpad]] spawn_when_empty` | Leeres Scratchpad startet per Toggle eine App (#255) | verfügbar, nicht genutzt |
| `input.client_window_drag = false` | Client-Move-Requests ignorieren (Titelleisten-Drag der Apps) (e0272e3) | verfügbar, nicht gesetzt (Default `true`) |
| `[input.touch]` (`enabled`, `map_to_output`) | Touchscreen mappen/ein-/ausschalten (#318) | IRRELEVANT (kein Touchscreen) |
| `output.<NAME>.screen_effect` | Screen-Effekt pro Output ersetzen/abschalten | verfügbar, nicht gesetzt |
| `[animation.windows_drag] physics = true` | Elastische Drag-Physik | verfügbar, nicht genutzt (Master-Switch nötig) |
| `[screencast] disable_dynamic_confirmation` | Bestätigungsdialog bei Target-Wechsel im Share abschalten | verfügbar, nicht gesetzt |
| `window-consume-from-left/right`, `window-move-left/right`, `window-swap-left/right/up/down` (Richtungs-Swaps), `output-create`/`output-destroy` | Neue Actions (Scrolling: consume/expel; Dwindle-Richtungs-Moves) | verfügbar, nicht gebunden |
| `animation.*.effect` (ersetzt `animation.*.shader`) | Animation nutzt jetzt benannte `[effects]`-Presets statt Shader-Pfad | nicht genutzt (wir nutzen nur `style`/`scale`) |
| `input.keyboard.model` | XKB-Tastaturmodell (z.B. `pc104angle`), global oder pro Keyboard (#413) | verfügbar, nicht gesetzt (System-Default) |
| `[input.drag_edge_scroll]` (`enabled`, `trigger_zone`, `delay_ms`, `max_speed`) | Edge-Scroll beim DnD/getilten Fenster-Move jetzt konfigurierbar (#401) | verfügbar, Defaults passen (nicht gesetzt) |
| `output.<NAME>.focus_at_startup` | Mauscursor beim Start auf diesen Monitor setzen (#390) | verfügbar, nicht gesetzt (nur 1 aktiver Output) |
| `window_rule.match.is_only_window` | Einziges Fenster auf dem Workspace (inkl. Floating) (#391) | verfügbar, nicht genutzt |
| `window_rule.confine_pointer` | Pointer im fokussierten Fenster halten (Spiele-Menüs) (#399) | verfügbar, nicht genutzt (2026-10-20 getestet u. wieder entfernt — stört Cross-Monitor-Wechsel auf lion) |
| `layer_rule.match.layer` / `match.at_startup` | Layer-Surface nach Ebene (`background`/`bottom`/`top`/`overlay`) bzw. Startphase matchen (#400) | verfügbar, nicht genutzt |
| `scratchpad-window-show-next/previous` | Scratchpad **ein Fenster zur Zeit** anzeigen statt alle (#376) | verfügbar, nicht gebunden (Alternative zu `scratchpad-focus-next`) |
| `workspace-set-layout toggle <mode1> <mode2>` | Toggle nur über eine Teilmenge der Layouts (#397) | verfügbar (wir nutzen bare `toggle`) |
| Umbriel veröffentlicht `XCURSOR_*` selbst (#384) | `XCURSOR_THEME/SIZE` werden vom Compositor an Clients gereicht | Hinweis: ggf. doppelt zu unserer `desktop.nix`/Steam-Wrapper-Setzung — noch unangetastet |
| Modale Dialoge an Parent gebunden (#215) | **ZURÜCKGENOMMEN** (`5731190`, 2026-10-10) — Verhalten wieder wie davor | Verhalten (automatisch) |
| HDR: EDID-Metadaten + Gamma-Erhalt | Mastering-Luminanz aus EDID; Night-Light-Gamma pausiert bei HDR | Verhalten (automatisch; wir fahren SDR 10-bit) |
| `animation.windows_resize` | Resize-Timing getrennt von `windows_move` (2026-10-17) | **GESETZT** (`250ms`/`snappy`, alle Hosts, 2026-10-20) |
| `layout.client_maximize` (`"column"`/`"edges"`, + per-Workspace) | Neuer Layout-Modus (#383) | verfügbar, nicht genutzt (Scrolling) |
| `layout.dwindle.preserve_split` (+ per-Workspace) | Dwindle-Split-Richtung erhalten | verfügbar, nicht genutzt (Scrolling) |
| `window_rule[].background_render` | Fenster im Hintergrund weiter rendern (2026-10-17) | verfügbar, nicht genutzt |
| `general.honor_restored_maximize` | Restored-Maximize respektieren (Default `false`) | verfügbar, nicht gesetzt |
| `input.keyboard.track_layout` (`"global"`/`"window"`) | Keymap-Wechsel pro Fenster/global | verfügbar, nicht gesetzt (Default `"global"`) |
| `output.<NAME>.sdr_transfer` (`"gamma22"`/`"srgb"`) / `sdr_white` (80–1000 Nits) | SDR-Transfer + Referenzweiß (HDR) | verfügbar, nicht gesetzt (Default `gamma22`/203) |
| Action `window-kill:[<id>]` | Prozess des Fensters beenden (2026-10-17) | **GEBUNDEN** (`Mod+Ctrl+Q`, alle Hosts, 2026-10-20) |
| Action `layout-toggle-split` | Dwindle-Split-Richtung togglen (#444) | verfügbar, nicht gebunden (Scrolling) |
| Actions `window-move-to:<anchor>/<x>/<y>` / `window-move-by:<dx>/<dy>` | Floating-Fenster pixelgenau verschieben (#451) | verfügbar, nicht gebunden |
| Action `output-sdr-white:<nits>[/<output>]` | SDR-Referenzweiß live setzen (#467) | verfügbar, nicht gebunden |
| Audio-reaktive `[effects]` (#455) | Noctalia-Spectrum-Snapshots für Shader | nicht genutzt |
| `layout.mode = "floating"` / `workspace-set-layout:floating` | Workspace-weit freie, überlappende Fenster (Windows-artig, Kaskade, Geometrie-Fokus; `d323128`) | verfügbar, nicht gesetzt (bleiben bei `scrolling`); `window-toggle-floating` wird dort abgelehnt |
| `[appearance.title_bar]` (`mode` = `off`/`on`/`forced`/`negotiated`, Buttons, Radius) | Server-seitige Titlebars inkl. Minimize (`1713992`) | verfügbar, nicht gesetzt (Default `off`) |
| `[input] window_snapping` | Kanten-/Ecken-Snap für schwebende Fenster — Default **`true`** seit `d88b0bc` | aktiv über Default (nicht explizit gesetzt) |
| Actions `window-snap:<region>` / `window-unsnap` | Floating halbe/viertel Bildschirme per Tastatur | verfügbar, nicht gebunden |
| `[input.focus] hover_raises` | Hover hebt Fenster an (opt-in, #556) | verfügbar, nicht gesetzt |
| `[input.touchpad] scroll_method` / `enabled` + Device-Overrides | Touchpad-Scroll-Methode bzw. gezielt an/aus (#518/#531) | IRRELEVANT (Touchpad systemweit aus) |
| `tap_and_drag` / `drag_lock` (Input) | Tap-and-Drag + Drag-Lock (#500) | verfügbar, nicht gesetzt |
| `window_rule.match.is_cast_target` | Fenster als Screencast-Ziel matchen | verfügbar, nicht genutzt |
| `layout.scrolling.center_on_overview_select` | gewählte Spalte beim Overview-Auswählen zentrieren (#494) | verfügbar, nicht gesetzt |
| `msg focused-window` | IPC-Abfrage des fokussierten Fensters (#572) | verfügbar (nur bei Bedarf) |
| Cursor-Actions (hide/show) | Cursor ein-/ausblenden (#529) | verfügbar, nicht gebunden |
| Scrollspalten breiter als der Output (Extent 0.1–4.0) | breite Spalten durchpannen (#569) | verfügbar, nicht genutzt |
| `[input] mod_right_double_click` | Mod+Doppel-Rechtsklick → Maximize (#504) | verfügbar, nicht gesetzt |
| `window_rule[].block_capture` | Fenster aus Screenshots/Aufnahmen ausblenden (#616) | verfügbar, nicht genutzt |
| `workspace-move-to-output <ziel>` (+ Richtungen) | ganzen Workspace auf anderen Output verschieben (#617) | verfügbar, nicht gebunden (1 aktiver Output) |
| `animation.windows_opacity` (enabled/curve/duration_ms) | Opacity/Blur von Window-Rules animieren (`2952bbcb`) | verfügbar, Default aktiv (keine Rule-Opacity genutzt) |
| `appearance.title_bar.button_glyph` (`hover`/`always`/`never`) + Hover-Sichtbarkeit | Titlebar-Buttons/Glyphen (`b1c3efc4`, `07d3e0bb`) | nicht genutzt (keine Server-Titlebars) |
| Actions `window-set-region <region>` statt `window-snap:<region>`; Layout `floating` → `stacking` | Rename (`b95c1ae5`) | nicht genutzt |
| `umbriel config validate --json`, `subscribe --json` | CLI-JSON-Ausgabe (`9180a954`) | verfügbar (nur bei Bedarf) |

## Zuletzt gecheckt
- **2026-10-31** (`8df1a18`/1424 → `2952bbc`/1459): **35 Commits, 2 Breaking Changes**.
  `umbriel config validate` = `config: ok` auf allen 4 Hosts (nach Migration).
  1. `e8ab5b00` (breaking): Actions `name:arg` → **Wort-Argumente**. 221 Bindings in allen
     4 Hosts migriert (`workspace-switch 7`, `window-move-to-workspace 1`, `spawn ...`,
     `scratchpad-toggle default`, `session-quit skip-confirmation`, `workspace-set-layout toggle`).
  2. `b1c3efc4` (breaking): Titlebar-Buttons → tri-state `button_glyph` (Default `hover`);
     wir setzen keine Titlebar-Optionen → keine Migration nötig.
  3. Weiter: `b95c1ae5` Floating-Layout → `stacking` + Snap-Actions ersetzt; `69a348c2`
     Workspaces zwischen Outputs verschieben; `2952bbcb` Opacity/Blur in Window-Rules animieren;
     `07d3e0bb` Titlebar-Glyphen/Hover; `9180a954` `config validate --json`.
- **2026-10-28** (Lock-Update via `nix-check`; `3667399`/1400 → `b456dc29`/1418):
  **18 Commits, KEINE Breaking Changes** (kein `!`). `umbriel config validate` =
  `config: ok` auf allen 4 Hosts gegen das neue Binary.
  **Kernthemen:**
  1. **Screen-Sharing/InputCapture**: `InputCapture`-Portal **v2** (`d4a513e`),
     genehmigte Capture-Sessions merken (`4fa14f1`), Capture-Pointer-Regionen
     publizieren (`8121647`), Doku zu Screen-Sharing (`55027a6`).
  2. **Xwayland**: gemappte Popups neu klassifiziert (`8d29e73`), gepufferte
     Surfaces nach später Zuordnung mappen (`8b7a76e`).
  3. **Fenster/Fokus**: Transient-Fokus + abgerissene Menüs (`1d81acb`),
     geteilter Keyboard-Lock-State (`910297e`).
  4. **Rendering**: `umbrielfx` rendert interne Framebuffer in gesampelte Texturen
     (`8c6e5c9`); Output meldet committeten Scanout-State + Historie (`47ee4cc`).
  5. libinput **1.29**, mehrere Portal-Input-Bumps.
  **Status:** Config unverändert gültig (additiv). `layout.mode` weiter `scrolling`.
- **2026-10-27** (Check gegen Upstream; Lock `d9497f3`/1398 vom 26.10., **live**;
  letzter dokumentierter Stand `b70b6fa`/1312): **86 Commits (1312→1398), 1 Breaking
  Change** (`refactor(scratchpad)!` `7b9ad2e` — liegt **vor** `b70b6fa`, betrifft uns
  nicht). **Nachgezogen auf HEAD `3667399`/1400** (2026-10-27): `155665c`
  per-window Shortcut-Inhibition + `3667399` Blur-Ecken unter Titlebars; alle 4
  Hosts `config: ok` gegen das neue Binary, Switch auf nex erledigt.
  **Kernthemen (additiv):**
  1. **Neues Layout `floating`** (`d323128`): Workspace-weit freie, überlappende
     Fenster, Kaskaden-Platzierung, Geometrie-Richtungsfokus,
     `workspace-set-layout:floating`. `window-toggle-floating` wird dort abgelehnt.
  2. **Server-seitige Titlebars** (`e3534ac` u.a.): `appearance.title_bar.mode`
     (`off` Default / `on` / `forced` / `negotiated`), Buttons, Minimize
     (`1713992`), Corner-Radius, sichtbar bei Maximize-to-Edges.
  3. **Floating-Snapping**: `[input] window_snapping` (**Default `true`** seit
     `d88b0bc`), Actions `window-snap:<region>`/`window-unsnap`, `snap` im IPC.
  4. **Input**: xdg-Toplevel-Drag, `tap_and_drag`/`drag_lock`, Touchpad
     `scroll_method`, `[input.touchpad].enabled` + Device-Overrides,
     `[input.focus] hover_raises` (opt-in, #556), libei 1.3 + X11-Input-Hints,
     autorisierte Xwayland-Input-Emulation, Mod-Doppel-Rechtsklick → Maximize.
  5. **Layout/IPC**: Scrollspalten breiter als der Output (#569),
     `center_on_overview_select`, `msg focused-window` (#572), Cursor-Actions,
     `is_cast_target`-Rule, `appearance.tab_bar.window_gap`.
  6. **HDR/Perf**: native HDR-Clients + Gamescope (`3507948`), Auto-HDR-Fixes;
     Default-**Blur-Passes 3 → 2** (`54abe52`).
  7. **Scratchpad**: leeres Toggle + Direktstart, fokussiertes Fenster zentrieren
     (#546), Workspace-Move-Bindings für Scratchpad-Fenster.
  **nixpkgs-Stand (2026-10-27):** `umbriel 0-unstable-2026-10-16` (`5cea311`) →
  **älter** als unser Pin → weiter Flake-Input.
  **Status:** Config unverändert gültig (nur additive Keys); `layout.mode` bleibt
  `scrolling`. `input.window_snapping` bewusst beim Default (`true`) gelassen.
- **2026-10-20** (Update auf Rev `b70b6fa`, revCount 1312; letzter dokumentierter
  Stand `1a58290`/1200): **112 Commits (1200→1312), 2 Breaking Changes** (kein
  Schema-Bruch bei uns). `umbriel config validate` = `config: ok` auf allen 4
  Hosts (mortiferus/backbone/lion/benny) gegen das neue Binary (Rev 1312).
  **Kernthemen (alles additiv/optional):**
  1. **Breaking (nicht betroffen):** `feat(audio)!` (#455) — `[effects]` akzeptiert
     jetzt Noctalia-Spectrum-Snapshots (audio-reaktiv); `refactor(scratchpad)!`
     (`7b9ad2e`) — `animation.scratchpad`-*Placement*-Keys durch Window-Rules
     ersetzt (Animations-Keys `blur`/`dim`/`effect` bleiben). Wir nutzen weder
     `[effects]` noch Placement-Keys → keine Migration.
  2. **Verhalten geändert (wichtig):** `revert` (#215, `5731190`, 2026-10-10) —
     modale Dialoge werden **nicht mehr** an den Parent gebunden (kein Beschatten/
     Mitbewegen). Tracker-Eintrag ist als zurückgenommen markiert.
  3. **Neue Config-Keys (nicht gesetzt):** `animation.windows_resize` (Resize-
     Timing getrennt von `windows_move`), `layout.client_maximize`
     (`"column"`/`"edges"`, neuer Layout-Modus #383, + per-Workspace),
     `layout.dwindle.preserve_split`, `window_rule[].background_render`,
     `general.honor_restored_maximize` (Default `false`),
     `input.keyboard.track_layout` (`"global"`/`"window"`), HDR/SDR:
     `output.<NAME>.sdr_transfer` (`"gamma22"`/`"srgb"`) + `sdr_white`
     (80–1000 Nits, Default 203). Siehe Tracker.
  4. **Neue Actions:** `window-kill` (Prozess beenden), `layout-toggle-split`
     (Dwindle-Split-Richtung), `window-move-to:<anchor>/<x>/<y>` +
     `window-move-by:<dx>/<dy>` (Floating pixelgenau), `output-sdr-white:<nits>`.
     `window-kill` gebunden (`Mod+Ctrl+Q`), `window-move-to-workspace-silent`
     gebunden (`Mod+Shift+Ctrl+1..9`), uebrige nicht.
  5. **Automatisch:** Night-Light jetzt auch bei HDR (`76f66c4`), Xwayland reicht
     Scale/Cursor-Theme via XSETTINGS (`8d9806f`), Keymap aus systemd-localed wenn
     `[input.keyboard]` keine XKB-Namen setzt (`f8285f8`), Live-Animation für
     Workspace-Reveals (`d083f24`), optimierter Blur als Paket-Default
     (`62799bd`). Zahlreiche Fixes (Blur, Syncobj/explicit-sync, IPCs, Scratchpad,
     Output-Swapchain-Recovery, …).
  6. **Hinweis:** Die mitgelieferte Default-Config wurde umformatiert/`[general]`
     auskommentiert (`acb5ae7`/`165a386`) — betrifft nur die Defaults, nicht
     unsere Config.
  **Status:** Config unverändert gültig (additiv). `switch` + Login-Neustart holt
  das neue Binary (Rev 1312) in die Sitzung.
- **2026-10-08** (Update auf Rev `1a58290`, revCount 1200; letzter dokumentierter
  Stand `4c89178`/1167): **33 Commits (1167→1200), KEINE Breaking Changes**
  (kein `!`-Marker, keine Key-Umbenennung). `umbriel config validate` = `config: ok`
  auf allen 4 Hosts (mortiferus/backbone/lion/benny) gegen das neue Binary (Rev 1200).
  **Kernthemen (alles additiv/optional):**
  1. **Neue Config-Keys (nicht gesetzt):** `input.keyboard.model` (XKB-Modell, #413),
     `[input.drag_edge_scroll]` (`enabled`/`trigger_zone`/`delay_ms`/`max_speed`, #401 —
     Edge-Scroll beim DnD/Fenster-Move jetzt konfigurierbar statt fix),
     `output.<NAME>.focus_at_startup` (#390), `window_rule.match.is_only_window`
     (einziges Fenster inkl. Floating, #391), `window_rule.confine_pointer`
     (Pointer im fokussierten Fenster halten — für Spiele-Menüs, #399),
     `layer_rule.match.layer` + `match.at_startup` (#400). Siehe Tracker.
  2. **Neue Actions:** `scratchpad-window-show-next`/`-previous` (#376) zeigen ein
     Scratchpad **Fenster für Fenster** statt alle gleichzeitig — direkte Alternative
     zu unserem `scratchpad-focus-next`. `workspace-set-layout:toggle:<mode1,mode2>`
     (#397) zykelt nur eine Teilmenge der Layouts.
  3. **Verhalten (automatisch):** modale Dialoge an den Parent gebunden (#215:
     Parent beschattet, kein Fokus/Input, bewegt sich mit); `input.focus.follows_mouse`
     verfeinert (Scrollen/Drag unter stehendem Pointer ändert den Fokus nicht);
     spät gemappte Fenster nach Workspace-Slide versteckt (#409); Xwayland-Fullscreen
     bleibt compositor-owned bis eine Umbriel-Action es beendet; optimized blur folgt
     Layer-Animationen; HDR nutzt EDID-Mastering-Metadaten und erhält Gamma über
     HDR-Übergänge.
  4. **Wichtig als Hinweis:** Umbriel **veröffentlicht `XCURSOR_*` selbst** (#384).
     Wir setzen die Cursor-Variablen bisher redundant in `desktop.nix`
     (`environment.sessionVariables`) und im Steam-Wrapper — perspektivisch
     vereinfachbar, aber unkritisch.
  5. **Fixes (automatisch):** Xwayland-Fokus/Selections, Pointer-Tear-off-Output,
     Hover nach Touchpad-Scroll, Focus-Erhalt beim Layout-Scroll, workspace-slide.
  **Status:** Config unverändert gültig (additiv). `switch` + Login-Neustart holt das
  neue Binary (Rev 1200) in die Sitzung.
- **2026-10-06** (Update auf Rev `4c89178`, revCount 1167; letzter dokumentierter
  Stand `dceb9924`/1072): **95 Commits (1072→1167), 1 Breaking Change** (nur
  Verhalten, kein Schema) + **1 CLI-Rename**. `umbriel config validate` =
  `config: ok` auf allen **4** Hosts (mortiferus/backbone/lion/benny) gegen das
  NEUE Binary (`nix build …programs.umbriel.package --no-link`). **Kernthemen:**
  1. **`feat(xwayland): replace xwayland-satellite with native wlroots Xwayland`**
     (`16d5031`, 2026-09-29): Umbriel startet Xwayland jetzt selbst (lazy, beim
     ersten X11-Client) und braucht `Xwayland` statt `xwayland-satellite` auf
     `PATH`. Neuer Key `general.xwayland_native_resolution` (Default `false`).
     **Umsetzung:** `xwayland-satellite` aus `modules/desktop/umbriel.nix`
     entfernt (war nur noch ein ungenutztes Paket). Das Flake-Paket wrappt
     `Xwayland` via `makeBinaryWrapper` selbst in den PATH des Compositors
     (verifiziert: `/nix/store/…-xwayland-24.1.13/bin` im Wrapper);
     `programs.xwayland` (shared `desktop.nix`) liefert das Binary. Kein
     systemd-Service, kein Doppelstart. `xwayland_native_resolution` nicht
     gesetzt — alle Outputs `scale = 1.0`, daher wirkungslos.
  2. **CLI-Rename** (`f66d6a8`, 2026-09-27): `umbriel validate` → **`umbriel
     config validate`**, neu `umbriel config schema [--json]` (listet jeden
     akzeptierten Key inkl. Typ/Default). **Kein Alias** — altes `validate` weg.
     Docs (umbriel.md/memory.md) angepasst.
  3. **Breaking (nur Verhalten, dwindle)**: `feat(dwindle)!` (`4062917`) —
     Richtungs-Moves in Dwindle legen Fenster in Nachbarkacheln, neue
     `window-move-left/right` + `window-swap-*`. **Kein Config-Key betroffen,
     wir nutzen `layout.mode = "scrolling"`** → keine Migration.
  4. **Große additive Features (nicht gesetzt):** Tab-Gruppen
     (`[layout.tabs]`/`[appearance.tab_bar]`/`[colors.tab_bar]`, Tab-Actions),
     GLSL-`[effects]`-Engine (Presets/Pools/`effect-*`-Actions, ersetzt
     `animation.*.shader` durch `animation.*.effect`), Screencast-Actions +
     `[screencast]`, `match.app_id/title/xdg_tag`/`namespace` als Array,
     `window_rule.default_column_display`/`border_effect`/`window_effect`,
     `[[scratchpad]] spawn_when_empty`, `default_focused` bei Scratchpad,
     `input.client_window_drag`, `[input.touch]`, `output.screen_effect`,
     `[animation.windows_drag] physics`, Virtual Outputs
     (`output-create`/`output-destroy`). Alle optional/Default-off.
  5. **Nebenfund:** lion's **generierte** (gitignored) `noctalia.toml` (vom
     2026-09-09) enthielt noch `colors.border.scratchpad_focused/unfocused` —
     Keys, die im neuen Schema **entfernt** wurden (nur noch
     `focused`/`unfocused`/`outer`; Scratchpad-Border läuft jetzt über
     `window_rule.border_color_*` + `match.is_scratchpad`). mortiferus/benny
     regenerieren die Datei bereits ohne diese Keys. Die zwei Zeilen in lion's
     Datei entfernt → alle 4 Hosts `config: ok`.
  **Status:** Config unverändert gültig, ein Modul-Fix (xwayland) + lion-Artefakt.
  `switch` + Login-Neustart holt das neue Binary in die Sitzung (User).
- **2026-09-26** (Lock-Update auf Rev `dceb9924`, revCount 1072; letzter
  dokumentierter Stand `b83ccfd`/997): **75 Commits (997→1072), KEINE Breaking
  Changes / kein Config-Schema-Wandel**
  (kein `!`-Marker, keine Key-Umbenennung). `umbriel validate` = `config: ok`
  auf allen 3 Hosts erwartet — unsere Keys (`[animation]` easeout/snappy +
  `duration_ms`, window_rules `blur`/`opacity`/`vrr`/`content_type`/`xdg_tag`,
  `default_*`) sind unverändert gültig. **Kernthemen (alles additiv/optional):**
  1. **Animations-Ausbau**: Defaults jetzt spring-basiert (`duration_ms=250`,
     `curve="easeout"`; jedes Event defaultet auf einen Spring). **Spring-Syntax
     gewechselt** → `curve = "spring:<damping>,<stiffness>"` (z.B. `"spring:1,900"`)
     + Namens-Registry `[animation.springs]`/`[animation.beziers]` (die frühere
     `curve = "spring"` + `spring = {}`-Tabelle von `c6d7d57` ist damit obsolet —
     wir nutzen sie nicht). Neu: `style`-Werte `popin`/`zoom`/`slide`/`fade`/`none`,
     `shader` (Custom-GLSL, `reveal.glsl`/`squash.glsl`), Lifecycle-Animationen
     („open tiled alongside reflow", „crossfade tiled", „fade as a whole").
  2. **Neue Config-Keys (ungenutzt)**: `appearance.opaque_fullscreen` (#242),
     `output.<NAME>.bit_depth` (10-bit-SDR, #172), `output.<NAME>.cyclic_workspaces`
     (#267), `input.*.left_handed` (#282), `input.touchpad.tap_button_map` (#301),
     Window-Rule-Deko-Overrides `border_width`/`outer_border_width`/`corner_radius`/
     `shadow` (#266) + `border_color_*` (#268), Aktion `window-move-to-workspace-silent`
     (#273). Siehe Feature-Tracker oben.
  3. **Fixes (automatisch)**: Focus/Fullscreen bei Workspace-Swap & Top-Layer,
     Fullscreen-Fokus-Preserve, Login-PATH-Vererbung, `environment.d`-Pfad,
     `new_exits_fullscreen` jetzt auch für floating/pinned (#249), VRR-/
     Overview-/Scratchpad-Fixes, umbrielfx sRGB/BGRA-Fixes.
  **Status**: Lock gezogen, Config unverändert sauber — **kein Handlungsbedarf**;
  `switch` + Login-Neustart auf nex holt das neue Binary in die Sitzung.
- **2026-09-22** (Lock-Update auf Rev `b83ccfd`, revCount 981→997): seit `8929c2d`
  **16 Commits, KEINE Breaking Changes / kein Schema-Wandel** genau wie der
  Lock-Stand verspricht. `umbriel validate` = `config: ok` auf allen 3 Hosts
  (mortiferus/backbone/lion, gegen das neue Binary). **Kernthemen:**
  1. **Animations-Rework („simpler")** `fb7ac63` + Spring-Physik `c6d7d57`/
     `7869dab`: Defaults window → 200ms/150ms easeout; neue Config-Kurve
     `curve = "spring"` mit `spring = { damping, stiffness }` (Spring leitet
     seine Dauer selbst ab; `duration_ms` nur für zeitbasierte Kurven). Unsere
     `cfg/animation.toml` (easeout/snappy + duration_ms) bleibt valide →
     **kein Handlungsbedarf**; nur falls gewünscht: `windows_move` auf `"spring"`.
  2. **Session**: `51e6528` startet gestartete Apps in **transienten
     systemd-Scopes** (Isolation) — automatisch, passend zu unserem
     systemd-user-Autostart gilt nichts zu tun.
  3. **Fixes/Perf (automatisch)**: Overview-Karten-Reveal/Hide (`d60d3ab`,
     `2bd2dfd`), IME-Keymaps-Sync (`30f8c8d`), Fullscreen-Open/Arten
     (`b83ccfd`, `5eb49b6`). 3 reine Doku-Commits (`aece01c`, `9c1596a`,
     `12f4123`) liegen bereits über dem Pin → holt der nächste `nix flake update`.
  **Status**: Config unverändert sauber; `switch` lief heute bereits mit b83ccfd
  → **Login-Neustart auf nex** holt das neue Binary in die Sitzung.
- **2026-09-20** (Update auf Rev `8929c2d`, `nix flake update`): seit `2f2e4e3a` **28 Commits, keine Breaking Changes, kein Config-Schema-Wechsel** (Parser/Config unberührt) → keine Migration nötig.
  **Kernthemen:**
  1. **Animationen maßvoll überarbeitet**: Sammel-Revert `31601e0` („drop all recent animations work", zu viele Regressions) → danach gezielt neu eingeführt: `feat(layout) animate tiled windows + close ghosts` `3649a44`, `fix(animation) preserve tiled close lifetime` `8929c2d`, `distinguish built-in window slide`, `keep consume/expel transitions direct`. Overview: Spring-Tail-Fixes (`f0b3830`, `76cede1`). Falls visuelle Animationen komisch wirken → liefert diese Rev-Bewegung die Erklärung.
  2. **`feat(output): support protocol-driven output disable`** (`61c580b`): Outputs per Protokoll de-/aktivierbar (z.B. Docking, wlr-randr/Ext-Management) — kein Config-Key.
  3. **Scratchpad-/Fokus-Fixes**: `keep visible scratchpad focus on workspace switch` (#245, `a00cabf`); `scratchpad scope retention` (`2625236`); **Portal-Dialoge erben Scratchpad-Parent** (`42e7ef3`) — gut für Steam/Electron-Dialoge.
  4. **Sonstiges** (automatisch): `fix(output) cover physical edges at fractional scales` (`bc95a27`), `fix(input) refresh hover after client fullscreen exit` (`aa9d523`), `perf(umbrielfx) disable implicit flush` (#228), Tests für Focus-Stealing/Scratchpad, Doku (Guix), `window-toggle-floating` mit optionalem Action-Arg (#252). Kein Handlungsbedarf.
  **Status**: Laufender Stand sauber; `umbriel validate` = `config: ok` erwartet, Switch + Login-Neustart offen (user macht das).
- **2026-09-17** (Update auf Rev `2f2e4e3a`, `nix flake update`): seit `6ca1d08` 8 Commits (RevCount 945→953).
  **3 Breaking Changes, alle = „extent-based sizing vocabulary" (Width/Height → Primary/Secondary Extent):**
  1. `feat(config)!: rename layout.scrolling default width to extent` (`32cc131`):
     `layout.scrolling.default_width_fraction` → **`default_extent_fraction`** (auch `output.<NAME>.layout.scrolling.*`).
  2. `Default Size Refactor #229` (`8a2c591`): Window-Rules umbenannt —
     `default_size = [w,h]` → **`default_floating_size_px = { width, height }`**;
     `default_width` (tiled scrolling) → **`default_scrolling_extent`**;
     `default_height` → `default_floating_size` (nicht genutzt).
  3. `feat(layout)!: adopt extent-based sizing vocabulary` (`2f2e4e3`): Actions + `width_presets` umbenannt —
     `layout.width_presets` → **`extent_presets`**;
     `window-cycle-width` → **`window-cycle-primary-extent`** (analog `-height` → `-secondary-extent`,
     `window-modify-width/height` → `window-modify-primary/secondary-extent`, `window-set-*` ebenso).
  **Alle 3 Hosts migriert** (layout.toml, keybinds.toml `Mod+R`, rules.toml) → `umbriel validate` = `config: ok`
  gegen die laufende (neue) Binary auf nex; backbone/lion per `-c` validiert. Sonstiges Neues (automatisch):
  `new_exits_fullscreen` (#240), `layout.master.new_becomes_master` (#174), center-master (#140), per-axis
  Touchpad-Scroll-Factor (#222), resize-from-named-edge (#208), Keyboard-Shortcut-Inhibition (9453b67) —
  kein Handlungsbedarf (optionale Keys).
- **2026-09-10** (Update auf Rev `293724d`, `nix flake update`): seit `a588733d` ~19 Commits (RevCount 874→893).
  **Keine Breaking Changes / keine Config-Umbenennungen.** Kernthema = **PR #214: `xdg-foreign-unstable-v2`**
  (Server-Protokoll): Dialoge werden jetzt über dem Parent platziert (auch „center a dialog over what shows
  of its parent", „float dialogs whose parents are still opening"). Relevant für sandboxed Clients (Steam FHS,
  Electron), läuft automatisch, kein Config-Key nötig.
  - Sonstige Neue (automatisch, kein Handlungsbedarf): `ipc`-Workspace-Occupancy, Overview-Touchpad-Nav (2 Achsen),
    Animation Shader-Feedback/Random-Seeds, sRGB-Erhalt auf SDR-Outputs, Output-Mode-Fallback (#188),
    `center_focused = "on_overflow"` (Rework #110), Hot-Corners-Fix bei Fullscreen, Keyboard-Restore nach Entfernung,
    Decoration-Drag-Pointer-Lock-Fix (fix #201).
  - Tracker-Status unverändert: `match.is_alone`, `default_scratchpad`, named Workspaces weiterhin „verfügbar/ungenutzt" –
    wir nutzen Integer-Workspaces + `:default`-Scratchpad (kein Handlungsbedarf).
  - Host-Configs (mortiferus/backbone/lion) gecleant: gleiche Keys, lion mit eigenen Display/Rule-Anpassungen.
    Validate gegen NEUES Binary ausstehend → beim nächsten Switch mit prüfen (`umbriel validate`).
- **2026-09-09** (Update auf Rev `a588733d`): ~91 Commits seit `786c237`. **3 Breaking Changes**, alle geprüft:
  1. `center_focused` von Boolean zu String (`"never"`/`"always"`/`"on_overflow"`) — nicht gesetzt, kein Handlungsbedarf.
  2. `expand_single_column` entfernt — nicht genutzt, kein Handlungsbedarf.
  3. Scratchpads global + named (statt per-output): Bare Actions brauchen jetzt `[<scratchpad>]` Suffix.
     **Gefixt**: `scratchpad-toggle` → `scratchpad-toggle:default` in allen 3 Hosts (mortiferus/backbone/lion).
  Neue Features: `match.is_alone` Window-Rule (Fenster-Breite abhängig ob allein), named workspace targets
  (`default_workspace = "CHAT"`), `default_scratchpad` Window-Rule. Fixes: Input strands (#160/#191),
  Suspend/Resume Workspaces (#27), Overview badges (#158), overview opacity clamp (#195), sRGB auf SDR,
  fullscreen exit tiled size, border shader highp (#171), config array merge (#175).
  `umbriel validate` = `config: ok` auf allen Hosts.
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