# NixOS Memory (Current State)

## Module Structure

### System
- `system/common.nix` – imports noctalia + greeter + quiet-sessions
- `system/environment-common.nix` – base env (31 Zeilen)
- `system/nix-ld.nix` – nix-ld mit allen Libraries
- `system/cachyos-tuning.nix` – shared sysctl/udev/systemd/journald/PAM/bpftune
- `system/btrfs.nix` – scrub + balance via `my.btrfs.fileSystems`
- `system/boot-common.nix` – importiert cachyos-tuning + btrfs + CachyOS pinned Overlay + tmpfiles für `/var/lib/nixos`

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
- **Lutris**: `lutris-unwrapped` aus nixpkgs + `steam-run` Wrapper für FHS-Umgebung
  - **Font-Problem**: Schriften erscheinen als kleine Quadrate (Fontconfig findet Fonts nicht in FHS-Umgebung)
  - **Lösung**: Eigene `lutris-fontconfig` Derivation mit allen Font-Packages (Noto, Corefonts, Nerd Fonts)
  - `FONTCONFIG_FILE` zeigt auf Nix-Store-Pfad (nicht `/etc/fonts/fonts.conf`, das ist in steam-run nicht erreichbar)
  - `fc-cache -fs` baut Cache vor Lutris-Start neu
  - **PROTONPATH-Problem**: umu-launcher versucht GE-Proton von GitHub zu laden (Codename `GE-Proton`), schlägt fehl
   - **Lösung**: Wrapper erstellt Symlink `~/.local/share/Steam/compatibilitytools.d/GE-Proton11-1` → Nix-Store (`proton-ge-bin.steamcompattool`)
  - umu-launcher findet GE-Proton lokal via `_get_from_compat` als Fallback

### Services
- `services/noctalia.nix` – v5 package (kein systemd-Konflikt mit HM-Modul)

### Hardware
- `hardware/legion.nix` – Legion Conservation Mode + Kernel-Modul
- `hardware/nvidia.nix` – NVIDIA PRIME Offload
  - `vulkan-validation-layers` entfernt (Debug-Tool, nicht nötig für Gaming, Build-Fehler mit Sandbox)
  - `vkbasalt` als System-Vulkan-Layer in `hardware.graphics.extraPackages` (64-Bit + 32-Bit)
    - GOverlay zeigt "not found" an (kein CLI-Binary in nixpkgs), funktioniert aber in Spielen
    - Aktivierung via `ENABLE_VKBASALT=1 %command%` in Steam

### Home-Manager
- `home/mortiferus/{default,packages,config,autostart,mpv}.nix` (mangohud.nix gelöscht – Config wird von GOverlay verwaltet)
- `home/backbone/{default,packages,config,autostart}.nix`
- Default-Nix importiert `./autostart.nix`
- **Noctalia State-Symlink** (v5, 2026-07-24 – korrigiert):
  - `~/.local/state/noctalia` → `/etc/nixos/home/mortiferus/state/noctalia` (GUI-State + interner State)
  - **Wichtig**: `home.file.mkOutOfStoreSymlink` funktioniert **nicht** – Home-Manager überschreibt den Symlink bei jedem Rebuild mit einem Store-Pfad
  - **Lösung**: `home.activation` Script in `config.nix` (mortiferus + backbone), das nach `writeBoundary` den Symlink robust aufs Repo setzt
  - `~/.config/noctalia` wird von v5 nicht mehr genutzt (v4-Überbleibsel entfernt)

### Design-Regeln
- Jede Datei = ein Thema
- Große Dateien (>100 Z.) in fachliche Teile splitten
- Home-Manager: pro User ein Verzeichnis, pro Thema eine Datei
- Gaming: als Verzeichnis mit Submodulen pro Service/Script
- Jede `.nix`-Datei hat einen deutschen Header-Kommentar (1-3 Zeilen), der erklärt was das Modul macht
- Bei sysctl-/kernel-Parametern: Inline-Kommentar in Deutsch was der Wert bewirkt
- **System-Bau**: Nur mortiferus baut das System neu. Alias `nix-switch` = `sudo nixos-rebuild switch --flake /etc/nixos#(hostname)` (in `programs/tools.nix`). Wenn ich (opencode) Änderungen mache, niemals manuell rebuilden – nur Dateien editieren.

## Bekannte Probleme

### Atlas Air: Physischer Mute-Schalter stört Audio-Output
- **Problem**: Wird der Flip-to-Mute Schalter am Headset benutzt, fällt der Ton am Output aus und wieder ein
- **Ursache**: Headset-Firmware unterbricht beim Muten kurz den Wireless-Link zwischen Headset und Dongle (kein HID-Event, kein ALSA-Control-Change, kein USB-Reset in Linux sichtbar)
- **Workaround**: Mute nur per Software (`wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle`) und physischen Schalter ignorieren
- **Keybind**: `Mod+Shift+M` in Niri (`keybinds.kdl`)
- **USB Autosuspend** wurde als Ursache ausgeschlossen (udev-Regel in `atlas-air.nix` hat nichts gebracht)

## Noctalia v5

### Config-Struktur (wichtig: v5 ≠ v4)
- **GUI-State** (automatisch geschrieben): `~/.local/state/noctalia/` (Symlink aufs Repo)
  - `settings.toml` – alle Settings-UI-Änderungen (Greeter-Sync, Auto-Sync, etc.)
  - `clipboard/`, `plugin-cache/`, `state.toml` – interner State
  - v5 verwaltet alles unter `~/.local/state/noctalia`, `~/.config/noctalia` wird nicht mehr genutzt
- Start via `systemd --user` Service (graphical-session.target, nicht per Compositor-Spawn)
- IPC: `noctalia msg ...`
- `programs.noctalia.settings` wird **nicht** gesetzt (konflikt mit State-Symlink)
- Alte v4-Daten in `~/.config/noctalia` (inkompatible Plugins, settings.toml, colors.json) entfernt

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
- **Polkit-Policy**: Eigene Policy-Datei überschrieben (`desktop/noctalia-greeter.nix`)
  - `allow_active` auf `yes` gesetzt (aktive Benutzer ohne Passwort)
  - `exec.path` auf absoluten Nix-Store-Pfad des Apply-Helpers
  - Zusätzlich `polkit.nix` mit JS-Regel als Fallback
- **Greeter-Sync ohne Passwort**:
  - Noctalia v5 bevorzugt intern `run0` statt `pkexec` (wenn verfügbar)
  - `run0` verwendet `systemd-run` und fragt für transient units → **keine** Noctalia-Policy greift
  - **Lösung**: `privilege_command = "pkexec"` in `settings.toml` (Polkit-Policy mit `allow_active = yes` greift direkt, kein Passwort nötig)
- **Cursor-Theme**: Greeter braucht Cursor-Theme **systemweit** installiert (nicht nur Home-Manager), da er vor User-Session läuft
  - `bibata-cursors` + `XCURSOR_THEME/XCURSOR_SIZE/XCURSOR_PATH` in `desktop/desktop.nix` (shared, beide Hosts via `common.nix`)
  - Steam-Override hat eigene `extraEnv` für die FHS-Umgebung

## Steam & Proton-GE

### Konfiguration
- `programs.steam.package = pkgs.steam.override` mit eigenen `extraPkgs` (mangohud, bibata-cursors)
- `extraCompatPackages = [ pkgs.proton-ge-bin ]` für Proton-GE Integration
- **Autostart** (2026-07-24): `STEAM_EXTRA_COMPAT_TOOLS_PATHS` wird **direkt im systemd-Service** (`home/mortiferus/autostart.nix`) gesetzt, nicht nur in `steam.override.extraEnv`
  - Grund: `extraEnv` im Steam-Override wirkt nur für manuelle Starts, der systemd-Service sieht sie nicht
  - `lib.makeSearchPathOutput "steamcompattool" "" [ pkgs.proton-ge-bin ]` baut den korrekten Pfad
  - Service nutzt trotzdem `pkgs.steam` als Basis für `ExecStart`, die Env-Variablen werden über `Service.Environment` injiziert

### Bekannte Probleme & Lösungen

**Problem**: Falsche Uhrzeit in Spielen (z.B. POE2) – Zeitzone nicht gesetzt (2026-06-30)
- **Ursache**: `TZ=""` (leer) in der Session → glibc/Proton fällt auf UTC zurück
- **Lösung**: Doppelstrategie
  - `environment.sessionVariables.TZ = "Europe/Berlin"` global (`environment-common.nix`)
  - `extraProfile = "unset TZ"` in Steam-FHS-Umgebung (`steam.nix` + `autostart.nix`)
- **Grund**: `TZ=Europe/Berlin` funktioniert in der FHS-Umgebung nicht zuverlässig, `unset TZ` zwingt glibc auf `/etc/localtime`

**Problem**: Proton-GE verschwindet plötzlich aus Steam (2026-06-26)
- **Lösung**: Variable direkt in `steam.override.extraEnv` setzen (nur für manuelle Starts relevant)
  ```nix
  let
    extraCompatPaths = lib.makeSearchPathOutput "steamcompattool" "" [ pkgs.proton-ge-bin ];
  in
  programs.steam.package = pkgs.steam.override {
    extraEnv = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = extraCompatPaths;
    };
  };
  ```

**Problem**: Proton-GE fehlt nach Reboot beim Autostart, ist aber da nach manuellem Neustart (2026-06-27, fix 2026-07-24)
- **Ursache**: systemd-Service verwendet `${pkgs.steam}` (Basis-Paket), nicht `programs.steam.package` (override mit extraEnv)
- **Lösung**: Umgebungsvariablen direkt im systemd-Service setzen:
  ```nix
  let extraCompatPaths = lib.makeSearchPathOutput "steamcompattool" "" [ pkgs.proton-ge-bin ];
  in
  systemd.user.services.steam.Service = {
    Environment = [
      "STEAM_EXTRA_COMPAT_TOOLS_PATHS=${extraCompatPaths}"
      "XCURSOR_THEME=Bibata-Modern-Ice"
      "XCURSOR_SIZE=24"
    ];
    ExecStart = "${pkgs.steam}/bin/steam";
  };
  ```
- **Zusätzlich**: `tmpfiles` erstellt Symlink `~/.local/share/Steam/compatibilitytools.d/GE-Proton-Latest` → Store (`proton-ge-bin.steamcompattool`)

### Proton-GE Paket
- `proton-ge-bin` aus nixpkgs (aktuell GE-Proton11-1)
- Output: `steamcompattool` enthält `compatibilitytool.vdf` + Proton-Scripts
- Pfad: `/nix/store/*-proton-ge-bin-GE-Proton*-steamcompattool/`

## MangoHud & GOverlay

### Konfiguration (2026-07-24)
- **GOverlay** steuert MangoHud – `goverlay` + `vulkan-tools` (vkcube Preview) in `home/mortiferus/packages.nix`
- **Home-Manager**: `programs.mangohud.enable = true`, `settings = { }` (leer)
  - Keine festen `settings` in Home-Manager, damit kein unveränderlicher Nix-Store-Symlink nach `~/.config/MangoHud/MangoHud.conf` entsteht
  - GOverlay schreibt die Config als reguläre Datei nach `~/.config/MangoHud/MangoHud.conf`
  - `mangohud.nix` (fixe Config) wurde gelöscht – alles wird von GOverlay verwaltet
- **Steam-FHS-Umgebung** sieht `~/.config/MangoHud/MangoHud.conf` (Home-Verzeichnis ist gemountet, Datei ist regulär und nicht ein Store-Symlink)
- **Steam-Launch-Option**: Weiterhin `mangohud %command%` in den Steam-Spieleigenschaften setzen
- **MangoHud-Toggle**: `Shift_R+F12` (oder via GOverlay neu belegen)

### PRIME Offload – GPU-Swap Workaround (2026-07-17)
- **Problem**: `lspci` zeigt `01:00.0` (NVIDIA) und `06:00.0` (AMD)
  - GOverlay baut Dropdown aus `lspci`, MangoHud `gpu_list` nutzt `/sys/class/drm/renderD*` Reihenfolge
  - Auf nex: render node order ist vertauscht → `gpu_list=0` = AMD, obwohl `lspci` es als NVIDIA listet
- **Lösung**: In GOverlay den "falschen" Eintrag wählen
  - NVIDIA-Stats: Dropdown-Eintrag `06:00.0` (AMD) auswählen → schreibt `gpu_list=0`
  - "Use both GPUs" → `gpu_list=0,1` (beide)
- **GPU-Label korrekt**: In GOverlay Metrics → GPU Name `RTX 3070 Mobile` eintragen
  - Schreibt `gpu_text=RTX 3070 Mobile`, damit Overlay richtig beschriftet ist

### Horizontal-Centering Workaround (2026-07-17)
- **Problem**: `position=top-center` zentriert das Fenster, nicht den Inhalt
  - Bei `horizontal` + `horizontal_stretch` (default) ist HUD zwar oben mittig, aber Inhalt linksbündig
  - MangoHud Issue #1746 – kein natives Content-Centering für horizontale Layouts
- **Lösung**: `position=top-left` + `offset_x=250` in GOverlay Visual → Position
  - Verschiebt HUD pixelgenau nach rechts, simuliert Zentrierung
  - Wert muss bei Auflösungswechsel neu angepasst werden

### Fazit (2026-07-24)
- **Keine Home-Manager/Repo-Integration** für MangoHud Config
  - Symlink auf `/etc/nixos/` funktioniert nicht in Steam's FHS-Umgebung
  - Automatisches Backup ist manuell und daher nutzlos → entfernt
  - GOverlay verwaltet `~/.config/MangoHud/MangoHud.conf` vollständig selbst
  - Wenn Config verloren geht: neu in GOverlay einstellen (dauert 2 Minuten)
- **GOverlay Abhängigkeiten** (2026-07-24):
  - `goverlay` + `vulkan-tools` (vkcube Preview) – beide in `mortiferus/packages.nix`
  - `vkbasalt` in nixpkgs ist Vulkan-Layer-Library (`libvkbasalt.so`), kein CLI-Binary → GOverlay zeigt "not found" an
  - **Aber**: vkBasalt als System-Layer in `hardware.graphics.extraPackages` installiert (64-Bit + 32-Bit)
  - Funktioniert in Spielen trotz GOverlay-Anzeige – Aktivierung via `ENABLE_VKBASALT=1 %command%` in Steam
  - Nicht in nixpkgs verfügbar: `vksumi`, `qt6pas` → bleiben rot in GOverlay, sind aber optional

## Cachix / Binary Caches
- `cache.nixos.org` – Offizieller NixOS Cache
- `nix-community.cachix.org` – Nix-Community Cache
- `noctalia.cachix.org` – Noctalia v5 Binaries
- `attic.xuyh0120.win/lantian` – CachyOS Kernel (xddxdd/nix-cachyos-kernel, primärer Cache)
- `cache.xinux.uz` – CachyOS Kernel Community-Mirror (bahrom04, alternativer Cache für Redundanz)

## bpftune
- `services.bpftune.enable = true` in `cachyos-tuning.nix`
- Oracle-Tool: dynamische Netzwerk-Auto-Optimierung via BPF (keine statischen sysctl nötig)
- Ersetzt manuelle TCP/Congestion/Buffer-Tuning: wählt pro Verbindung per Reinforcement Learning den besten CC-Algorithmus
- Tuner: TCP-Connection (CC-Auswahl), TCP/UDP-Buffer, IP-Frag, Neighbour/Route-Table, sysctl-Monitoring
- Deaktiviert Tuner automatisch bei manuellen sysctl-Überschreibungen

## systemd.user.services (aktuell)

### mortiferus (`home/mortiferus/autostart.nix`)
- `discord`: `After=graphical-session.target noctalia.service` (ersetzt vesktop wg. pnpm-CVEs)
- `steam`: `After=graphical-session.target noctalia.service`, `Environment` mit `STEAM_EXTRA_COMPAT_TOOLS_PATHS`, `XCURSOR_THEME`, `XCURSOR_SIZE`
- `udiskie`: `After=graphical-session.target noctalia.service`
- `polychromatic-tray`: `After=graphical-session.target noctalia.service`

### backbone (`home/backbone/autostart.nix`)
- `udiskie`: `After=graphical-session.target noctalia.service`

### Debug
- `systemctl --user status noctalia discord steam udiskie polychromatic-tray`

## Kernel
- Flake Input: `cachyos.url = "github:xddxdd/nix-cachyos-kernel/release"`
- Overlay: `cachyos.overlays.pinned` in `boot-common.nix` (shared, garantiert Cache-Treffer)
- **nex**: `cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3` (scx bpfland aktiv)
- **styx**: `cachyosKernels.linuxPackages-cachyos-latest`
- scx (bpfland) aktiv auf nex, Performance-Modus in `boot-nex.nix`
- `nixpkgs-small` entfernt (war nur für CachyOS-Tests, wird nicht mehr benötigt)
- `smallPkgs` aus `nvidia.nix` entfernt, nutzt jetzt `pkgs.mesa`

## Legion Conservation Mode (`hardware/legion.nix`)
- `systemd.services.legion-conservation-mode`: setzt `conservation_mode = 1` bei jedem Boot
- Pfad: `/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode`
- `After=systemd-modules-load.service`, `WantedBy=multi-user.target`
- Runtime-Toggle: `echo 0 | sudo tee /sys/.../conservation_mode` (bis Reboot)

## Thunar Erweiterungen (vorgemerkt, 2026-07-24)

Status: `modules/home/thunar.nix` wurde bei Git-Reset entfernt (uncommitted). Inhalt zur Wiederverwendung dokumentiert.

### Geplante Features
| # | Feature | Beschreibung |
|---|---|---|
| 08 | `thunar-extract-here` | Rechtsklick-Menü: Archiv im aktuellen Ordner extrahieren |
| 09 | `thunar-extract-to-folder` | Rechtsklick-Menü: Archiv in neuen Unterordner extrahieren |

### Offene Entscheidung
- Thunar vs. Nautilus – noch nicht final entschieden
- Wenn Thunar: `thunar.nix` neu erstellen mit Extract-Actions
- Wenn Nautilus: Features werden nicht benötigt (Nautilus hat native Extract-Funktion)

## Package-Audit (2026-07-11)

Überflüssige/ redundante Pakete entfernt. Bei Problemen mit Apps → prüfen ob das entfernte Paket doch nötig war.

### Entfernte Pakete

| Paket | Datei | Grund der Entfernung |
|---|---|---|
| `xsel` | `mortiferus/packages.nix` | X11-Clipboard, `wl-clipboard` reicht (auch XWayland) |
| `xclip` | `mortiferus/packages.nix` | X11-Clipboard, `wl-clipboard` reicht |
| `xdotool` | `mortiferus/packages.nix` | X11-Automatisierung, `ydotool` ist Wayland-Ersatz |
| `wf-recorder` | `mortiferus/packages.nix` | Deprecated, ungewartet |
| `htop` | `environment-common.nix` | `btop` macht dasselbe |
| `satty` | `mortiferus/packages.nix` | Screenshot-Annotation, nicht nötig (Niri/Noctalia Screenshots direkt ins Clipboard) |
| `swappy` | `mortiferus/packages.nix` + `noctalia.nix` | Screenshot-Annotation, nicht nötig |
| `mangohud.nix` | `mortiferus/` | Fixe MangoHud-Config, wird jetzt von GOverlay verwaltet |
| `vulkan-tools` | `mortiferus/packages.nix` | Wieder hinzugefügt (2026-07-24) – wird von GOverlay für vkcube Preview genutzt |
| `git` | `backbone.nix` (User) | Bereits systemweit in `environment-common.nix` |
| `openldap` | `environment-common.nix` | LDAP-Libs, nötig für nix-ld (bleibt dort), systemweit unnötig |
| `gnome-themes-extra` | `mortiferus/packages.nix` | Redundant mit `orchis-theme` |
| `cacert` | `mortiferus/packages.nix` | NixOS handled CA-Zertifikate systemweit, `nix-shell -p` (ohne `--pure`) erbt System-Umgebung |
| `faugus-launcher` | `gaming/default.nix` | 4. Game-Launcher, Steam/Heroic/Lutris reichen |
| `ladspa-sdk` | `audio.nix` | SDK für Entwicklung, `ladspaPlugins` reicht für Audio-Plugins (Chatmixer etc.) |

### Behalten mit Begründung

| Paket | Grund |
|---|---|
| `protonplus` | Nutzer bekommt Proton-Versionen die Steam nicht anbietet |
| `samba` | Netzwerk-Zugriff zwischen allen Rechnern gewünscht |
| `brightnessctl` | Fallback in Niri-Keybinds (`keybinds.kdl`) + Hyprland + Gaming-Scripts |
| `dlss-swapper` / `dlss-swapper-dll` | DLSS-Preset-Override + NGX-Updater |
| `prusa-slicer` / `orca-slicer` / `ideaMaker` | Verschiedene UIs, jeder Slicer hat andere Features |
| `slurp` | Region-Selection für manuelle Screenshots |
| `grim` | Screenshot-Tool (Wayland-nativ) |
| `libsForQt5.qt5ct` | Qt5-Legacy, behalten für Kompatibilität |
| `shared-mime-info` | Mime-Type-Datenbank, wird von Apps benötigt |
| Hyprland + `hyprshot` | Gelegentliche Tests, nicht komplett entfernt |
| `goverlay` | MangoHud-GUI-Konfigurator, verwaltet `~/.config/MangoHud/MangoHud.conf` |
| `vulkan-tools` | GOverlay Live-Preview (vkcube) + Vulkan-Debugging |
| `vkbasalt` | Vulkan-Post-Processing-Layer (Visuelle Effekte in Spielen) |
