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

## Open Points
- `styx`-Host: gleiches Deployment via `sudo nixos-rebuild switch --flake .#styx`
- `pkgs.noctalia-shell` in nixpkgs ist v4.7.7 (EOL) – v5 nur via Flake
