# Migration Memory: DMS → Noctalia v5

## Why
- **DMS (DankMaterialShell)**: v1.5-beta Flake, keine Cachix-Binaries → lokaler Build
- **Noctalia v5**: Cachix `noctalia.cachix.org` hat Binaries für v5, in nixpkgs nur v4 EOL
- **Ziel**: v5 aus Cachix, kein systemd für noctalia (Compositor-Autostart), zentraler Greeter

## Migration Date
2026-06-24/25

## Bootstrap-Problem
- `nix-settings.nix` mit `noctalia.cachix.org` konnte nicht aktiv werden, weil der Build den Cache braucht, der Cache aber erst nach Build im System bekannt ist
- **Lösung**: 2-Phasen-Build:
  1. Noctalia deaktiviert → rebuild → Cache-Konfig aufs System
  2. Noctalia reaktiviert → rebuild zieht noctalia v5 aus Cachix

## What changed

### New
- `modules/services/noctalia.nix` – v5 package, kein systemd
- `modules/desktop/noctalia-greeter.nix` – zentraler greeter (nicht per-host)
- `modules/system/common.nix` – imports noctalia + greeter + quiet-sessions

### Deleted
- `modules/services/dms.nix` – dead code
- `hosts/nex/greeter.nix` – per-host dms-greeter
- `hosts/styx/greeter.nix` – per-host dms-greeter
- `home/*/config/niri/dms/` – stale dms configs
- `home/*/config/hypr/dms/` – stale dms configs
- `home/*/config/DankMaterialShell/` – stale dms configs

### Changed
- `flake.nix`: `dms-shell` → `noctalia` + `noctalia-greeter` (beide ohne `follows` für Cachix)
- `nix-settings.nix`: `noctalia.cachix.org` in substituters + trusted-public-keys
- `common.nix`: `dms.nix` → `noctalia.nix`, `quiet-sessions.nix` re-enabled
- Niri configs: `dms ipc call` → `noctalia msg`, `^dms-wallpaper` → `^noctalia-wallpaper`, `spawn-at-startup "noctalia"`
- Hyprland configs: `noctalia-shell` → `noctalia`, `dms ipc call` → `noctalia msg`
- HM symlinks: `DankMaterialShell` → `noctalia`

## Noctalia v5 Config
- Settings file: `~/.config/noctalia/settings.toml` (v4-format, kompatibel)
- Start via Compositor: `spawn-at-startup "noctalia"` (niri) / `exec_cmd("noctalia")` (hyprland)
- IPC: `noctalia msg ...`

## Noctalia IPC Commands
| Action | Command |
|---|---|
| Launcher/Spotlight | `noctalia msg spotlight toggle` |
| Powermenu | `noctalia msg powermenu toggle` |
| Settings | `noctalia msg settings toggle` |
| Clipboard | `noctalia msg clipboard toggle` |
| Notifications | `noctalia msg notifications toggle` |
| Notepad | `noctalia msg notepad toggle` |
| Lock | `noctalia msg lockscreen lock` |
| Volume up | `noctalia msg audio increment 5` |
| Volume down | `noctalia msg audio decrement 5` |
| Mute | `noctalia msg audio mute` |
| Brightness up | `noctalia msg brightness increment 5` |
| Brightness down | `noctalia msg brightness decrement 5` |

## Noctalia-Greeter
- `programs.noctalia-greeter.enable = true` + `--session niri`
- Config per `environment.etc."noctalia-greeter.toml"`
- Upstream-Bug: `tomlFormat.generate` (derivation) kann nicht in `C.argument` (string) → umgangen via `systemd.tmpfiles`

## Cachix
- Cache: `noctalia.cachix.org`
- Public Key: `noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=`
- CI Build #1864 für Commit `2d53f6ab` → success
- Build aus Cache bestätigt nach Bootstrap

## 2026-06-25: Autostart-Cleanup & Greeter-Sync Automation

### Problem
- Steam lief 2x: XDG Autostart (`~/.config/autostart/steam.desktop`) + Noctalia Startup Hook (`~/Apps/autostart.sh`)
- Gleiches für Vesktop (`~/.config/autostart/vesktop.desktop`)

### Fix
- `~/.config/autostart/steam.desktop` gelöscht
- `~/.config/autostart/vesktop.desktop` gelöscht
- Beide laufen nur noch über Noctalia Startup Hook (`~/Apps/autostart.sh`)

### Greeter-Sync Automation
Damit der Greeter bei jedem Wallpaper-Wechsel automatisch die aktuellen Farben + Wallpaper übernimmt:
- **`modules/desktop/desktop.nix`**: Polkit-Regel für `org.noctalia.greeter.apply-appearance` (passwordlos für `mortiferus`)
- **`home/mortiferus/config/noctalia/wallpaper-change.sh`**: Script das `noctalia msg greeter-sync` ausführt
- **`settings.json`**: `wallpaperChange`-Hook zeigt auf das Script
- Effekt: Bei jedem Wallpaper-Wechsel (alle 30 Min. / manuell) syncen ohne Passwort-Prompt

### Noctalia Hooks (aktuell)
| Hook | Script |
|---|---|
| `startup` | `/home/mortiferus/Apps/autostart.sh` |
| `wallpaperChange` | `/etc/nixos/home/mortiferus/config/noctalia/wallpaper-change.sh` |

## 2026-06-25: Modul-Refactoring (Phase 1)

### Ziel
Jede `.nix`-Datei = genau ein Thema. Dateiname sagt, was drin ist.

### Was sich geändert hat

**Tote Dateien gelöscht:**
- `modules/desktop/sddm.nix` + `sddm-themes/` – auskommentiert
- `modules/desktop/greetd.nix` + `greetd.nix-bk` – durch noctalia-greeter ersetzt
- `modules/programs/gaming.nix` – durch `gaming/`-Verzeichnis ersetzt
- `modules/home/*.nix` (mortiferus.nix + backbone.nix) – durch Verzeichnisse ersetzt

**Aufgesplittete Module:**

| Alte Datei | Neue Dateien |
|---|---|
| `desktop/desktop.nix` | `desktop/polkit.nix`, `desktop/fonts.nix`, `desktop/nautilus-emblems.nix`, `desktop/desktop.nix` (reduziert) |
| `system/environment-common.nix` | `system/nix-ld.nix`, `programs/zen-policies.nix`, `environment-common.nix` (reduziert) |
| `boot-nex.nix` + `boot-styx.nix` | `system/cachyos-tuning.nix` (shared) + reduzierte Host-Dateien |
| `programs/gaming.nix` | `programs/gaming/{default,steam,lutris,gamemode,gamescope,sunshine,scripts}.nix` |
| `home/{mortiferus,backbone}.nix` | `home/{mortiferus,backbone}/{default,packages,config}.nix` + mortiferus: `mangohud.nix`, `mpv.nix` |

**Neue Module:**
- `system/cachyos-tuning.nix` – shared sysctl/udev/systemd/journald/PAM
- `system/btrfs.nix` – scrub + balance via `my.btrfs.fileSystems`
- `system/nix-ld.nix` – nix-ld mit allen Libraries
- `programs/zen-policies.nix` – Zen-Browser Enterprise Policies
- `programs/ideamaker.nix` – ideaMaker Desktop-Entry
- `programs/gaming/lutris.nix` – custom Lutris-Wrapper (steam-run)
- `desktop/polkit.nix`, `fonts.nix`, `nautilus-emblems.nix`

**Import-Ketten optimiert:**
- `boot-common.nix` importiert jetzt `cachyos-tuning.nix` + `btrfs.nix` → Hosts importieren nur noch `boot-common.nix`
- styx: doppelter `editor.nix`-Import entfernt, `earlyoom` gelöscht, `smartd` (war in laptop-common) entfernt
- `cudaSupport` von styx/config → `environment-styx.nix`
- `systembus-notify` von legion.nix → `desktop/desktop.nix` (shared)
- `ideamaker` aus `users/mortiferus.nix` → `programs/ideamaker.nix`

**Größen:**
- `environment-common.nix`: 151 → 31 Zeilen
- `boot-nex.nix`: 170 → 24 Zeilen
- `boot-styx.nix`: 118 → 20 Zeilen
- `styx/configuration.nix`: 29 → 7 Zeilen

### Design-Regel für neue Module
- Jede Datei = ein Thema
- Große Dateien (>100 Z.) in fachliche Teile splitten
- Home-Manager: pro User ein Verzeichnis, pro Thema eine Datei
- Gaming: als Verzeichnis mit Submodulen pro Service/Script
- `system/btrfs.nix`: `my.btrfs.fileSystems`-Option setzt Ziel-Filesysteme für scrub + balance

## Open Points
- `styx`-Host: gleiches Deployment via `sudo nixos-rebuild switch --flake .#styx`
- `pkgs.noctalia-shell` in nixpkgs ist v4.7.7 (EOL) – v5 nur via Flake
