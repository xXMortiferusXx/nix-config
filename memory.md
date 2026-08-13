# NixOS Memory (Current State)

## Module Structure

### System
- `system/common.nix` – imports noctalia + greeter + quiet-sessions
- `system/environment-common.nix` – base env (31 Zeilen)
- `system/environment-nex.nix` – nex-spezifische Env (NVIDIA Shader-Cache, Explicit-Sync, Flipping)
- `system/nix-ld.nix` – nix-ld mit allen Libraries
- `system/cachyos-tuning.nix` – shared sysctl/udev/systemd/journald/PAM/bpftune
- `system/btrfs.nix` – scrub + balance via `my.btrfs.fileSystems`
- `system/boot-common.nix` – importiert cachyos-tuning + btrfs + tmpfiles für `/var/lib/nixos`
- `system/boot-nex.nix` – xanmod + scx_bpfland (Auto-Modus), **keine AMD-iGPU-Parameter mehr** (NVIDIA-only)

### Desktop
- `desktop/desktop.nix` – shared desktop config (reduziert)
- `desktop/polkit.nix` – Polkit-Regeln
- `desktop/fonts.nix` – Fonts
- `desktop/nautilus-emblems.nix` – Nautilus Emblems
- `desktop/noctalia-greeter.nix` – zentraler greeter (nicht per-host)
- `desktop/niri.nix` – niri via sodiboo/niri-flake (Flake-Paket + niri-unstable + niri.cachix.org Cache)

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
- `hardware/nvidia.nix` – NVIDIA PRIME Offload (archiviert unter `archive/modules/hardware/nvidia-prime.nix`)
  - `vulkan-validation-layers` entfernt (Debug-Tool, nicht nötig für Gaming, Build-Fehler mit Sandbox)
  - `vkbasalt` als System-Vulkan-Layer in `hardware.graphics.extraPackages` (64-Bit + 32-Bit)
    - GOverlay zeigt "not found" an (kein CLI-Binary in nixpkgs), funktioniert aber in Spielen
    - Aktivierung via `ENABLE_VKBASALT=1 %command%` in Steam
- `hardware/nvidia-only.nix` – **NVIDIA-only Modus für nex** (2026-08-12)
  - Kein PRIME-Block, kein `amdgpu` in `boot.initrd.kernelModules`
  - `powerManagement.finegrained = false` (nicht nötig ohne PRIME)
  - Wayland-Optimierungen: `GBM_BACKEND=nvidia-drm`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `__GL_VRR_ALLOWED=1`
  - `LIBVA_DRIVER_NAME=nvidia` + `VDPAU_DRIVER=nvidia` für Hardware-Decoding
  - `NIXOS_OZONE_WL=1` für Electron-Apps nativ auf Wayland
  - `__GL_EXPLICIT_SYNC_ENABLED=1` + `__GL_ALLOW_FLIPPING=1` in `environment-nex.nix`

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
- **Commits**: opencode darf commits und pushes ausführen, aber **erst nach erfolgreichem Test und explizitem "Grünem Licht" von mortiferus**. Damit bleiben Änderungen auf GitHub nachvollziehbar und plausibel für Dritte, die das Repo betrachten.
- **Saubere History**: Trial-and-Error-Commits werden vor dem Push entfernt oder gesquashed. Nur funktionierende, sinnvolle Commits landen auf GitHub. Bei größeren Experimenten: lokalen Branch nutzen und erst nach Erfolg in `main` rebasen/mergen.
- **Home-Manager vs. Systemweit**: Home-Manager nur für **User-spezifische** Configs (nur ein Benutzer betroffen). Alles was systemweit gilt (alle User, Compositor, Dateimanager, Tools) wird über `environment.etc` oder NixOS-Module konfiguriert. Store-Symlinks aus HM werden von vielen Apps nicht korrekt gelesen (siehe MangoHud, Thunar).

## Niri Quelle & Binary Cache (2026-07-27)

### Warum sodiboo/niri-flake statt nixpkgs oder offiziellem Flake
- **nixpkgs (vorher)**: `libdisplay-info` 0.4.0 brach niri-Build (Rust-Crate fordert `< 0.4.0`). Temporärer upstream-Bug.
- **Offizielles niri-Flake**: Kein Binary-Cache → lokales Kompilieren auf jedem Host nötig (10–40 Min.)
- **sodiboo/niri-flake**: Community-Flake mit `niri.cachix.org` Cache + automatisierte CI-Builds
  - Cache-Public-Key: `niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=`
  - `niri-stable` (letztes getaggtes Release) und `niri-unstable` (aktueller main)
  - Wir nutzen `niri-unstable` für aktuellsten Stand (war vorher auch main)

### Setup
- `flake.nix`: Input `github:sodiboo/niri-flake`
- `modules/desktop/niri.nix`: Cache + `package = inputs.niri.packages.${system}.niri-unstable;`
- NixOS-Modul von sodiboo wird **nicht** importiert (würde nixpkgs-Modul deaktivieren und Konflikte mit unserer Portal/Polkit-Config erzeugen)
- Stattdessen: Flake-eigenes Paket (eigenes gelocktes nixpkgs) + Cache manuell setzen

### Kein Overlay (seit 2026-08-06)
- `inputs.niri.overlays.niri` wurde **entfernt**: Das Overlay baut gegen das lokale nixpkgs und
  brach an `libdisplay-info_0_2` (aus nixpkgs entfernt, "unused in Nixpkgs").
- Das Flake-eigene Paket `inputs.niri.packages.${system}.niri-unstable` nutzt das im niri-flake
  gelockte nixpkgs und kommt aus dem `niri.cachix.org` Binary Cache (kein lokaler Build).

### Fallback bei Problemen
1. Cache nicht erreichbar → Nix baut lokal (dauert länger, aber funktioniert)
2. sodiboo-Flake broken → Zurück zu `pkgs.niri` aus nixpkgs (wenn upstream Bug gefixt)
3. `niri-unstable` zu instabil → Auf `inputs.niri.packages.${system}.niri-stable` wechseln (älterer, getaggter Release)

## Virtual Surround / HRTF (2026-07-31, final 2026-08-13)

### Setup (aktuell)
- **Game-Audio**: PipeWire `filter-chain` + **Convolver** mit `atmos.wav` (Dolby Atmos IR)
  - Schneller als SOFA-Spatializer (FFT-basiert), kein sporadisches Knacken
  - Headset-neutral: verfaelscht das Klangbild des Atlas Air nicht
  - Ortung funktioniert gut (Positionserkennung erhalten)
- **Chat-Audio**: SOFA-Spatializer (H19) fuer Discord/Voice — nur 1 Kanal, CPU-Last vernachlaessigbar
- **Quantum 512** (`modules/hardware/audio.nix`) — ausreichend fuer Convolver, niedrigere Latenz als 1024

### Archivierte Setup-Varianten
- ~~SADIE II D2 (KEMAR, 256 Taps)~~ — verworfen: generische HRTF passt nicht zu den Ohren, verfaelscht Klangbild
- ~~SOFA-Spatializer fuer Game~~ — verworfen: Knacken unter CPU-Last, schlechtere Ortung als Convolver
- ~~Quantum 1024~~ — verworfen: haette das Knacken nicht behoben, Ursache war SOFA nicht das Quantum

### Bekannter PipeWire-Bug: `bqeq` Label
- `bqeq` existiert **nicht** in PipeWire 1.6.8 → muss `bq_lowshelf` / `bq_peaking` (mit Unterstrich) verwenden
- Falsches Label crasht die komplette Filter-Chain → PoE1 hat lange nur 2 von 12 Kanälen ausgegeben
- **Fix**: Alle EQ-Nodes auf `bq_lowshelf` + `bq_peaking` umgestellt

### SADIE: Gain Compensation
- SADIE ist **nicht** generell lauter als andere HRTFs (RMS -39 dB vs -15 dB bei subject_003)
- **Aber**: Höhere Peak-Amplituden durch präzise 256-Tap-Convolution + Diffuse-Field-Equalisierung
- Bei **12 parallelen Kanälen** summiert sich SADIE konstruktiv auf → massive Übersteuerung
- **Community-Bekannt**: GitHub Issues (dhewm3 #768), Steam Audio Docs, Google VR-Studie warnen explizit vor SADIE-Clipping
- **Empfohlener Gain**: 2-6 dB für Stereo→Binaural, wir brauchen **-18 dB** für 12-Kanal→Binaural
- **Finaler Wert**: `-18.0 dB` via `bq_peaking` (Q=0.1, Breitband-Dämpfung) als Gain Compensation

### PoE1 Audio-Output
- PoE1 gibt tatsächlich **alle 12 Kanäle** aus (nicht nur Stereo!)
- `PathOfExileSteam.exe:output_FL` bis `output_TRR` → `GameSink:playback_*`
- FMOD in PoE1 upmixt 7.1 auf 12 Kanäle
- In-Game-Auswahl "GameSink" nötig für 7.1.4-Modus

### Atlas Air EQ
- **EQ komplett neutral** (0 dB) – SADIE braucht keine Korrektur, klingt pur perfekt
- Ursprüngliche Atlas Air EQ-Kurve (Dolby Smile + Korrektur) war für andere HRTFs gedacht

## Bekannte Probleme

### AX210: Ping-Spikes + Download-Einbruch bei Volllast (2026-08-12)
- **Problem**: Vollgas-Download über WLAN (1 Gbit) führt zu Ping-Explosionen (3000ms+) zum Router und Download bricht ein
- **Ursache**: Intel AX210 Combo-Chip (WiFi + BT) teilt Airtime intern, iwlwifi-Firmware `89.735b75a4.0` ist auf Linux tot gepflegt
- **Kernel-Log**: `iwlwifi: missed beacons exceeds threshold`, `Unhandled alg: 0x707`
- **Test 1**: `bt_coex_active=0` in `modules/hardware/wifi-iwlwifi-btcoex.nix` (BT-Koexistenz deaktiviert)
  - **Status**: Lösung verifiziert (2026-08-12). Ping bleibt unter Volllast stabil, nur normale ms-Schwankungen.
  - **Speedtest-Ergebnisse**: `wieistmeineip.de` = 1.078 Mbit/s, `fast.com` = 1,1 Gbps — beide ohne Drosselung oder Abbruch
  - **Einschränkung**: Bluetooth am AX210 ist ohne Koexistenz-Schutz (gleichzeitige WLAN+BT-Nutzung kann instabil werden)
  - **Langfristig**: Weiterbeobachtung über mehrere Tage (Steam-Downloads, Alltagsnutzung). Workaround funktioniert aktuell, aber ist kein "echter" Fix — Intel pflegt die AX210-Firmware für Linux nicht mehr. Entscheidung: Nicht sofort tauschen, aber Backup-Plan halten.

### AX210 Hardware-Upgrade-Plan (Backup)
- **Ziel**: Volle Performance + stabile Latenz unter Linux, ohne Treiber-Workarounds
- **Empfohlene Karte**: MediaTek MT7922 (M.2 2230) oder AMD RZ616 (rebadged MT7922)
  - Treiber: `mt7921e` (Kernel 5.16+, aktiv gepflegt von MediaTek)
  - WiFi 6E, 160 MHz, Bluetooth integriert
  - Linux-Support deutlich besser als AX210
- **Alternative**: USB-Stick mit MT7921AU-Chip (z.B. TP-Link Archer TX20U) für Plug & Play
- **Preis**: ~20-40€, Einbau: 1 Schraube M.2 2230
- **Status**: Nicht dringend, aber als Plan B festhalten

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

**Problem**: Gelegentliche Freezes in Steam (2026-08-13)
- **Ursache**: CEF (Chromium Embedded Framework) GPU-Beschleunigung in Steam kollidiert unter NVIDIA+Wayland/XWayland. Bekannter upstream-Bug (ValveSoftware/steam-for-linux #13000).
- **Lösung**: CEF-GPU-Beschleunigung deaktivieren (reduziert/eliminiert Freezes):
  - `ExecStart = "${steamPackage}/bin/steam -cef-disable-gpu-compositing -cef-disable-gpu"` im systemd-Service (`autostart.nix`)
- **Nicht verwenden**: `STEAM_DISABLE_HARDWARE_CURSORS = "1"` blockiert das System-Cursor-Theme (Bibata) in Steam — entfernt (2026-08-13, korrigiert).

**Problem**: Cursor-Theme (Bibata-Modern-Ice) in Steam nicht überall sichtbar (2026-08-13)
- **Ursache**: Steam's CEF-Teil (steamwebhelper, Chromium-basiert) nutzt GTK für Cursor-Rendering. `XCURSOR_THEME` reicht für native X11/Wayland-Apps, CEF/Chromium liest aber GTK-Settings (`~/.config/gtk-3.0/settings.ini`). Ohne GTK-Config zeigt CEF den Standard-Cursor.
- **Lösung**: `xdg.configFile."gtk-3.0/settings.ini"` in `home/mortiferus/config.nix` mit `gtk-cursor-theme-name=Bibata-Modern-Ice` und `gtk-cursor-theme-size=24`.

**Avatar/Profilbild im Greeter (2026-08-13)**
- `~/.face` wird von `accounts-daemon` automatisch erkannt und im Login-Screen (Noctalia-Greeter) angezeigt.
- **Home-Manager**: `home.file` erzeugt einen Store-Symlink, den `accounts-daemon` nicht lesen kann.
  - **Lösung**: `home.activation.createFaceAvatar` (analog zu `createNoctaliaState`), das nach `writeBoundary` einen Out-of-Store-Symlink `~/.face -> /etc/nixos/home/mortiferus/assets/face.png` setzt.
- **ACL-Mask Problem**: Home-Manager's `writeBoundary` setzt bei `nix-switch` die ACL-Mask auf `~` auf `---` (chmod synchronisiert Mask mit Unix-Gruppenrechten). Das blockiert `greeter`/`accounts-daemon`.
  - **Lösung**: `home.activation.fixHomeAclMask` setzt nach `writeBoundary` automatisch `setfacl -m m::r-x ~`.
  - `setfacl` ist bereits systemweit verfügbar (via `acl` Abhängigkeit), kein explizites Paket nötig.

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
- `noctalia.cachix.org` – Noctalia v5 Binaries (Flake-Input: `github:noctalia-dev/noctalia/cachix`)

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
- **nex**: `boot.kernelPackages = pkgs.linuxPackages_xanmod_latest` + `scx_bpfland` (Auto-Modus, `--primary-domain=auto` per Default)
- **styx**: `boot.kernelPackages = pkgs.linuxPackages_latest`
- CachyOS-Kernel am 2026-08-06 entfernt (alte Configs in `archive/cachyos-kernel/` für Wiederherstellung)
- `nixpkgs-small` entfernt (war nur für CachyOS-Tests, wird nicht mehr benötigt)
- `smallPkgs` aus `nvidia.nix` entfernt, nutzt jetzt `pkgs.mesa`
- **nex NVIDIA-only** (2026-08-12):
  - `amdgpu.dcfeaturemask`, `amdgpu.dcdebugmask`, `nvidia.NVreg_DynamicPowerManagement` entfernt
  - Alte `boot-nex.nix` mit PRIME-Parametern archiviert unter `archive/modules/system/boot-nex-prime.nix`
  - `amd_pstate=active` bleibt (AMD-CPU-PState, nicht GPU)

## Legion Conservation Mode (`hardware/legion.nix`)
- `systemd.services.legion-conservation-mode`: setzt `conservation_mode = 1` bei jedem Boot
- Pfad: `/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode`
- `After=systemd-modules-load.service`, `WantedBy=multi-user.target`
- Runtime-Toggle: `echo 0 | sudo tee /sys/.../conservation_mode` (bis Reboot)

## Thunar Erweiterungen (implementiert, 2026-07-27)

Status: `modules/desktop/thunar.nix` aktiv (importiert in `system/common.nix`)

### Features
| # | Feature | Beschreibung |
|---|---|---|
| 08 | `Entpacken → Hier entpacken` | Rechtsklick-Untermenü: Archiv direkt im aktuellen Ordner entpacken |
| 09 | `Entpacken → In Ordner entpacken...` | Rechtsklick-Untermenü: Archiv in neuen Unterordner (Archivname) entpacken |

### Implementierung
- `programs.thunar.enable = true` (kein Archive-Plugin – Custom Actions reichen)
- Custom Actions via `/etc/xdg/Thunar/uca.xml` (systemweit für alle User)
- Untermenü via `<submenu>Entpacken</submenu>` (Thunar gruppiert Actions automatisch)
- Helper-Script `thunar-extract` erkennt Format und nutzt passendes Tool (unzip, tar, 7z, unrar)
- Unterstützte Formate: zip, tar.gz/tgz, tar.bz2/tbz2, tar.xz/txz, tar, 7z, rar

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
| `orchis-theme` | `mortiferus/packages.nix` | Aus nixpkgs entfernt (Abhängigkeit `gtk-engine-murrine`/GTK 2 unmaintained, 2026-07-31) |
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

## Audio / ChatMixer (2026-08-13)

### Problem
Bei gleichzeitigem Game-Audio (7.1 H3-SOFA spatialisiert) und Discord/Chat-Audio entsteht Detailverlust, weil Game dauerhaft leiser gestellt werden muss, damit Chat durchkommt.

### Alte Lösung (archiviert): `chatduck`
Pegel-basiertes Auto-Ducking via `python3 + pw-record + wpctl`. Entfernt (2026-08-13), da generelles Leiser-machen von Game nicht zufriedenstellend war und die Audio-Qualität litt.

### Neue Lösung: ChatMixer DSP Engine
Statt Game leiser zu machen, wird Chat **praesenter und klarer** — durch HRTF + EQ + LADSPA Kompressor in einer PipeWire `filter-chain`.

```
Game (7.1) ──> AtmosFilter (H3 SOFA, Radius 150%) ──> Headset
                                                 (atmospherisch, luftig)

Chat/Discord ──> ChatSink ──> ChatFilter (HRTF frontal + EQ + Compressor) ──> Headset
                               (praesent, verstaendlich, im Kopf)
```

### LADSPA_PATH Fix (NixOS pipewire-Modul Bug)
- Das NixOS `pipewire`-Modul setzt `LADSPA_PATH` hardcoded auf `${pkgs.pipewire.ladspa-plugins}/lib/ladspa` — dieses Paket ist **leer**.
- **Fix**: `systemd.user.services.pipewire.environment.LADSPA_PATH = lib.mkForce "${pkgs.ladspaPlugins}/lib/ladspa";` in `audio.nix`.
- `lib.mkForce` ist noetig, weil das NixOS-Modul den gleichen Option-Pfad definiert und sonst ein Konflikt entsteht.

### ChatFilter-Chain (`chatmixer.conf`)
- **HRTF**: SOFA-Spatializer (Azimuth 0 degrees, Elevation 10 degrees, Radius 100%)
  - Chat klingt frontal/im Kopf, psychoakustisch getrennt vom Game
- **EQ**: `bq_peaking` bei 3000 Hz, Q=1.0, Gain=+6 dB
  - Boost im Sprachverstaendlichkeits-Bereich (2-4 kHz)
- **Kompressor**: LADSPA `sc1_1425` (Steve Harris Mono Compressor)
  - PipeWire fuehrt Mono-Plugins automatisch per Kanal fuer Stereo aus
  - **Explizite L/R-Pfade**: Zwei separate `sc1`-Instanzen (L+R) mit eigenen EQs, analog zur AtmosFilter-Chain
  - **Parameter** (optimiert fuer Sprache):
    - `Threshold level (dB)` = -35.0 (fruehes Greifen, auch bei leiser Stimme)
    - `Ratio (1:n)` = 3.0 (sanfte Kompression)
    - `Attack time (ms)` = 2.0 (schnelle Reaktion)
    - `Release time (ms)` = 200.0 (natuerlich fuer Sprache)
    - `Knee radius (dB)` = 6.0 (weiche Uebergaenge)
    - `Makeup gain (dB)` = 12.0 (lauteres Ausgangssignal)

### Game-Aenderung
- **HRTF-Radius**: 100% -> 150%
- Game klingt atmospherischer/luftiger, gibt Chat mehr Raum
- **Positionserkennung in Shootern bleibt erhalten** (nur Radius, keine Richtungsaenderung)

### Test-Script
- `home/mortiferus/scripts/test-chatsink.sh`: 5-Sekunden 1kHz Sine-Wave an ChatSink
  - Nutzung: `PULSE_SINK=ChatSink speaker-test -t sine -f 1000 -c 2 -l 1 -d 5`

### Files
- `home/mortiferus/config/pipewire/pipewire.conf.d/chatmixer.conf` — Game + Chat DSP Chains
- `modules/hardware/audio.nix` — `clock.quantum = 512` + LADSPA_PATH Fix
- `modules/home/mortiferus/autostart.nix` — chatduck entfernt
- `home/mortiferus/scripts/test-chatsink.sh` — ChatSink Test-Script

### Archivierte Experimente (PipeWire 1.6.8 Limits)
- LADSPA/LV2 Sidechain: PipeWire `filter-chain` unterstuetzt keinen externen Sidechain
- EasyEffects: Sidechain auf Hardware-Inputs beschraenkt, inkompatibel mit HRTF-Chain
