# NixOS Memory (Current State)

## Module Structure

### System
- `system/common.nix` – imports noctalia + greeter + quiet-sessions
- `system/environment-common.nix` – base env (31 Zeilen)
- `system/nix-ld.nix` – nix-ld mit allen Libraries
- `system/cachyos-tuning.nix` – shared sysctl/udev/systemd/journald/PAM
- `system/btrfs.nix` – scrub + balance via `my.btrfs.fileSystems`
- `system/boot-common.nix` – importiert cachyos-tuning + btrfs + CachyOS pinned Overlay

### Desktop
- `desktop/desktop.nix` – shared desktop config (reduziert)
- `desktop/polkit.nix` – Polkit-Regeln
- `desktop/fonts.nix` – Fonts
- `desktop/nautilus-emblems.nix` – Nautilus Emblems
- `desktop/noctalia-greeter.nix` – zentraler greeter (nicht per-host)
- `desktop/niri.nix` – services.gnome.gnome-keyring.enable

### Programs
- `programs/zen-policies.nix` – Zen-Browser Enterprise Policies
- `programs/ideamaker.nix` – ideaMaker Desktop-Entry
- `programs/gaming/` – als Verzeichnis mit Submodulen: `default`, `steam`, `lutris`, `gamemode`, `gamescope`, `sunshine`, `scripts`

### Services
- `services/noctalia.nix` – v5 package (kein systemd-Konflikt mit HM-Modul)

### Hardware
- `hardware/legion.nix` – Legion Conservation Mode + Kernel-Modul

### Home-Manager
- `home/mortiferus/{default,packages,config,autostart,mangohud,mpv}.nix`
- `home/backbone/{default,packages,config,autostart}.nix`
- Default-Nix importiert `./autostart.nix`

### Design-Regeln
- Jede Datei = ein Thema
- Große Dateien (>100 Z.) in fachliche Teile splitten
- Home-Manager: pro User ein Verzeichnis, pro Thema eine Datei
- Gaming: als Verzeichnis mit Submodulen pro Service/Script
- Jede `.nix`-Datei hat einen deutschen Header-Kommentar (1-3 Zeilen), der erklärt was das Modul macht
- Bei sysctl-/kernel-Parametern: Inline-Kommentar in Deutsch was der Wert bewirkt

## Noctalia v5

### Konfig
- Settings file: `~/.config/noctalia/settings.toml` (v4-Format, kompatibel)
- Start via `systemd --user` Service (graphical-session.target, nicht per Compositor-Spawn)
- IPC: `noctalia msg ...`
- `programs.noctalia.settings` wird **nicht** gesetzt (konflikt mit xdg.configFile-Symlink)

### IPC Commands
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

### Hooks
| Hook | Script |
|---|---|
| `wallpaperChange` | `/etc/nixos/home/mortiferus/config/noctalia/wallpaper-change.sh` |

### Noctalia-Greeter
- `programs.noctalia-greeter.enable = true` + `--session niri`
- Config per `environment.etc."noctalia-greeter.toml"`
- Upstream-Bug: `tomlFormat.generate` kann nicht in `C.argument` → umgangen via `systemd.tmpfiles`
- Polkit: `org.noctalia.greeter.apply-appearance` passwordlos für `mortiferus`

## Cachix / Binary Caches
- `noctalia.cachix.org` – Noctalia v5 Binaries
- `attic.xuyh0120.win/lantian` – CachyOS Kernel (xddxdd/nix-cachyos-kernel)

## systemd.user.services (aktuell)

### mortiferus (`home/mortiferus/autostart.nix`)
- `vesktop`: `After=graphical-session.target noctalia.service`, `ExecStartPre = sleep 3` (wg. Tray Race-Condition)
- `steam`: `After=graphical-session.target noctalia.service`
- `udiskie`: `After=graphical-session.target noctalia.service`
- `polychromatic-tray`: `After=graphical-session.target noctalia.service`

### backbone (`home/backbone/autostart.nix`)
- `udiskie`: `After=graphical-session.target noctalia.service`

### Debug
- `systemctl --user status noctalia vesktop steam udiskie polychromatic-tray`

## Kernel
- Flake Input: `cachyos.url = "github:xddxdd/nix-cachyos-kernel/release"`
- Overlay: `cachyos.overlays.pinned` in `boot-common.nix` (shared, garantiert Cache-Treffer)
- **nex**: `cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3` (BORE-Scheduler, kein scx)
- **styx**: `cachyosKernels.linuxPackages-cachyos-latest`
- scx (bpfland) auf nex deaktiviert (BORE inkompatibel), auskommentiert in `boot-nex.nix`
- Alter Kernel (`smallPkgs.linuxPackages_latest` / `linuxPackages_latest`) auskommentiert
- `nixpkgs-small` kann nach erfolgreichem Test entfernt werden

## Legion Conservation Mode (`hardware/legion.nix`)
- `systemd.services.legion-conservation-mode`: setzt `conservation_mode = 1` bei jedem Boot
- Pfad: `/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode`
- `After=systemd-modules-load.service`, `WantedBy=multi-user.target`
- Runtime-Toggle: `echo 0 | sudo tee /sys/.../conservation_mode` (bis Reboot)
