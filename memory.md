# NixOS Memory (Current State)

## Module Structure

### System
- `system/common.nix` – imports noctalia + greeter + quiet-sessions
- `system/environment-common.nix` – base env (31 Zeilen)
- `system/environment-nex.nix` – nex-spezifische Env (NVIDIA Shader-Cache, Explicit-Sync, Flipping)
- `system/nix-ld.nix` – nix-ld mit allen Libraries
- `system/cachyos-tuning.nix` – shared sysctl/udev/systemd/journald/PAM/bpftune
  - PAM: `@audio rtprio 99`
  - sysctl: `kernel.unprivileged_userns_clone=1` (Flatpak/Container)
- `system/ananicy.nix` – ananicy-cpp (Auto-Nice-Daemon) mit CachyOS-Regeln, cgroups deaktiviert (Konflikt mit bpftune)
  - nice/ionice/sched/oom automatisch pro Prozess (Game=LowLatency_RT, Chat, Service, etc.)
  - `GameMode` entfernt (CachyOS: "GameMode + ananicy-cpp = bad idea")
- `system/boot-common.nix` – importiert cachyos-tuning + tmpfiles für `/var/lib/nixos`
- `system/boot-nex.nix` – CachyOS-Kernel (seit 2026-08-20), scx_bpfland aktuell deaktiviert (pur getestet), **keine AMD-iGPU-Parameter mehr** (NVIDIA-only)

### Desktop
- `desktop/desktop.nix` – shared desktop config (reduziert)
- `desktop/polkit.nix` – Polkit-Regeln
- `desktop/fonts.nix` – Fonts
- `desktop/noctalia-greeter.nix` – zentraler greeter (nicht per-host)
- `desktop/umbriel.nix` – **Umbriel** (wlroots 0.20 + SceneFX) als einzige Wayland-Session (seit 2026-08-30)
  - Paket aus nixpkgs (`pkgs.umbriel`, PR #555208), Binaries aus `cache.nixos.org`
  - Session: `start-umbriel → umbriel.service → umbriel-session.target` (BindsTo graphical-session.target) — Autostarts (noctalia/steam/discord) laufen unverändert
  - xdg-Desktop-Portal: umbriel-Implementierung + GTK + gnome-keyring (Portal-Config kommt vom Modul, nicht überschreiben)
  - Details + Upstream-Tracking → `umbriel.md`
- niri **komplett entfernt** (2026-08-31): Modul, Flake-Input, niri.cachix-Cache, Config-Mounts. Alte Configs unter `archive/` (z.B. `archive/home/<user>/config/niri/`) + Git-History als Fallback

### Programs
- `programs/zen-policies.nix` – Zen-Browser Enterprise Policies
- `programs/ideamaker.nix` – ideaMaker Desktop-Entry
- `programs/gaming/` – als Verzeichnis mit Submodulen: `default`, `steam`, `gamescope`, `sunshine`, `scripts`
- **Lutris**: Standard-nixpkgs-Paket (`lutris`, buildFHSEnv) in `mortiferus.packages` (seit 2026-08-29)
  - Vorher: `lutris-unwrapped` + eigener `steam-run`-Wrapper in eigener `lutris.nix` — entfernt (Doppel-Sandbox: steam-run + UMU/pressure-vessel)
  - `lutris.nix` gelöscht, kein Font-Wrapper/`FONTCONFIG_FILE`-Hack mehr nötig

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
  - `powerManagement.finegrained = false` (geht nicht ohne PRIME-Offload, NixOS-Assertion)
  - `NVreg_InitializeSystemMemoryAllocations=0` (Performance)
  - `NVreg_DynamicPowerManagement=0x02` (GPU spart Strom bei Leerlauf)
  - `NVreg_EnableS0ixPowerManagement=1` (S0ix Idle-Power fuer AMD Ryzen)
  - Wayland-Optimierungen: `GBM_BACKEND=nvidia-drm`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `__GL_VRR_ALLOWED=1`
  - `LIBVA_DRIVER_NAME=nvidia` + `VDPAU_DRIVER=nvidia` für Hardware-Decoding
  - `NIXOS_OZONE_WL=1` für Electron-Apps nativ auf Wayland
  - VRAM-Heap-Fix: `GLVidHeapReuseRatio=0` für steamwebhelper, Discord, vesktop, umbriel (50-vram-fix.json)
  - `__GL_SHADER_DISK_CACHE_SIZE=12000000000` + `__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1` in `environment-nex.nix` (Shader-Cache 12 GB, global)
  - **Treiber**: `nvidiaPackages.stable` = 595.91.07 (seit 2026-08-16; vorher `latest` = 610.57.04, NVIDIA nennt 610 jetzt `new_feature`/`bleeding_edge`, 595 ist der `production`-Zweig)

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
- **FHS-Sandbox-Problem (gelöst 2026-08-20)**: `mkOutOfStoreSymlink` (Symlinks auf `/etc/nixos/...`) funktionieren **nicht** in FHS-Sandbox-Apps (Steam, etc.), weil bubblewrap `/etc` als tmpfs mounted und `/etc/nixos` nicht existiert.
  - **Lösung**: System-level Bind-Mounts via `systemd.mounts` (`hosts/<host>/config-mounts.nix`). `systemd.tmpfiles.rules` erstellt Ziel-Verzeichnisse, `systemd.mounts` mountet Repo-Config-Ordner direkt nach `~/.config/`. Keine Symlink-Auflösung nötig → FHS-Sandbox-Apps funktionieren universell.
  - **Wichtig**: Kein `Requires`/`After` auf `systemd-tmpfiles-setup.service` setzen — erzeugt einen Dependency-Cycle (`local-fs.target` → mount → tmpfiles → local-fs.target). Einfach `WantedBy = [ "multi-user.target" ]` reicht.
  - Home-Manager `xdg.configFile`-Einträge für `.config`-Ordner wurden entfernt. `home.file` (`.icons`, `.gtkrc-2.0`) und `home.activation` bleiben als HM-Symlinks (liegen in `$HOME`, nicht `.config`).

## Git / GitHub (2026-08-16)
- SSH-Key: `~/.ssh/github_ed25519` (ed25519, Kommentar `mortiferus@nex`), bei GitHub hinterlegt
- `~/.ssh/config`: `Host github.com` → `IdentityFile ~/.ssh/github_ed25519` + `IdentitiesOnly yes`
- Git-Identität global: `user.name=xXMortiferusXx`, `user.email=backilein@gmail.com`
- Remote: `git@github.com:xXMortiferusXx/nix-config.git` (SSH)
- `.git`-Ownership war nach Installation `root` (nixos-enter) → auf `mortiferus:users` gefixt

## Niri Quelle & Binary Cache (2026-07-27, HISTORISCH – niri entfernt 2026-08-31)

### Warum sodiboo/niri-flake statt nixpkgs oder offiziellem Flake
- **nixpkgs (vorher)**: `libdisplay-info` 0.4.0 brach niri-Build (Rust-Crate fordert `< 0.4.0`). Temporärer upstream-Bug.
- **Offizielles niri-Flake**: Kein Binary-Cache → lokales Kompilieren auf jedem Host nötig (10–40 Min.)
- **sodiboo/niri-flake**: Community-Flake mit `niri.cachix.org` Cache + automatisierte CI-Builds
  - Cache-Public-Key: `niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=`
  - `niri-stable` (letztes getaggtes Release) und `niri-unstable` (aktueller main)
  - Genutzt wurde `niri-unstable` (aktueller main)

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

## Virtual Surround / HRTF (EINGESTELLT 2026-08-16)

- **Kein Virtual Surround / kein HRTF / kein Convolver** — komplett deaktiviert
- Spiele und Chat klingen so, wie die Entwickler es vorgesehen haben (unverfaelscht)
- GameDAC bietet hardwareseitig räumliches Audio (DTS:X oder interner DSP) — GameDAC erzeugt Surround aus Stereo-Eingang
- **Quantum 512** (`modules/hardware/audio.nix`) bleibt — guter Kompromiss aus Latenz und Stabilität

### Verworfen (chronologisch)
- ~~SADIE II D2 (KEMAR, 256 Taps)~~ — generische HRTF passt nicht zu den Ohren
- ~~SOFA-Spatializer~~ — Knacken unter CPU-Last, schlechtere Ortung
- ~~Convolver mit atmos.wav (Dolby Atmos IR)~~ — Routing/Risiko-Problem
- ~~KU100_dry.sofa~~ — taugte nichts

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

### PoE1 Audio-Output (alter Stand, Loopback-Ära)
- PoE1 gab tatsächlich alle 12 Kanäle aus (FMOD upmixt 7.1 auf 12 Kanäle)
- Im aktuellen ACP-Profile-Setup: PoE1 sieht analog-game (6ch) + analog-chat (2ch) — getestet nötig

### SteelSeries GameDAC Gen1 (seit 2026-08-18, ersetzt Atlas Air)
- **USB ID**: 1038:1282 (Audio/Status) + 1038:1280 (HID/Controls)
- **Modus**: ALSA Card Profile — Custom Profile in `audio.nix` via `environment.etc`
  - Ersetzt das Pro-Audio Profil mit Chat + Game + Mic Mapping
  - WirePlumber-Config setzt `device.profile-set` + `device.profile` automatisch
  - Profile-Set: `steelseries-gamedac-usb-audio.conf` (aus [rockofox/steelseries-gamedac-pulseaudio](https://github.com/rockofox/steelseries-gamedac-pulseaudio), angepasst)
  - Path-Files: `steelseries-gamedac-output-game.conf`, `...-chat.conf`, `...-input.conf`
- **Output-Bezeichnung** (vertauscht zur Realität):
  - `SteelSeries GameDAC Spiel` (analog-game, 6ch) = **Game** (Spiele, Medien)
  - `SteelSeries GameDAC Unterhaltung` (analog-chat, 2ch) = **Chat** (Discord, Voice)
  - `SteelSeries GameDAC Mic` (analog-mic, 1ch) = **Mic** (48kHz Mono)
- **5.1 Audio**: Funktioniert — Spiele (Helldivers 2, PoE2) senden auf allen 6 Kanälen (FL FR FC LFE RL RR)
- **Channel-Namen**: Standard-Names (FL FR FC LFE RL RR) statt AUX0-AUX5 — Wine/Proton erkennt 5.1 korrekt
- **Volume-Default**: 100% (kein `volume = merge` — GameDAC hat keine ALSA Volume-Controls, nur Mute-Switches)
- **USB-C nur**: Anschluss über USB-C hinten am Laptop (Adapter nötig)
  - **PROBLEM**: An internen USB-A Ports (Genesys Logic Hub 05e3) crasht der GameDAC bei Mic-Aktivierung
  - Ursache: Bidirektional-Wechsel löst USB-Reset aus, Genesys-Hub propagiert auf alle Downstream-Ports
  - Externer USB-Hub funktioniert ebenfalls (anderer Hub-Chip)
- **Firmware**:
  - OLED zeigt: `DSP: 4.91.39.44 | MCU: 1.40.0 | Headset: 2.3`
  - USB bcdDevice: Audio `0003` (0.03), HID `0140` (= MCU 1.40)
  - Letztes öffentlich dokumentiertes FW-Update: Engine 3.12.11 (Sep 2018) — DTS Headphone:X v2.0
  - **DTS:X Bug**: Bekannter Firmware-Bug — DTS:X Processing crasht bei Signaländerung (Spielstart, Format-Wechsel). Toggle off/on am GameDAC = einziger Workaround. Auf Linux: Known Limitation.
  - **DTS:X Ursache (2026-08-25)**: Fehlende SteelSeries GG Keep-Alive HID-Befehle. Ohne GG (Linux) crasht DTS:X-DSP. Auf Windows mit GG: Keep-Alive stabilisiert DTS:X. Toggle-Befehl (`0x51`) für Gen1 nicht reverse-engineered.
  - **DTS:X USB-Strom-Theorie**: Möglicherweise instabile USB-Spannung bei Lastspitzen. Seit USB-2-Hub mit externer Stromversorgung tritt der Bug nicht mehr auf.
- **HID-Interface** (teilweise reverse-engineered):
  - `hidraw6` (PID 1280, interface 0): Command `0x20` (Status) funktioniert — 64-Byte Frame, Byte 6 = DTS:X State
  - `hidraw7/8` (PID 1280, interface 1/2): Keine Antwort
  - `hidraw5` (PID 1282): BrokenPipeError (falsches Interface)
  - Command `0x51` (Surround-Toggle): Keine Antwort auf Gen1 — nur Arctis Pro Wireless dokumentiert
- **Mic**: Separate Features (Noise Gate, NC, EQ) fehlen auf Linux. Sidetone funktioniert via HID `0x39`.
- **Open-Source-Projekte** (keines hat Gen1 DTS:X Support): Arctis-Sound-Manager, steelseriesgg-rs, HeadsetControl, steelclock-go, Linux-Arctis-Manager

## lsfg-vk (Frame Generation Layer, seit 2026-08-27)

### Quelle: Umzug von GitHub auf git.lsfg-vk.dev
- **Flake-Input**: `lsfg-vk-src.url = "git+https://git.lsfg-vk.dev/lsfg-vk.git?ref=master";` (`flake = false`)
- **Codebasis neu aufgebaut** (v2): `helper/`/`pipeline/`/`config/` statt altem `backend/`/`common/`
- CMake-Option umbenannt: `LSFGVK_BUILD_VK_LAYER` → `LSFGVK_BUILD_LAYER`; neu: `LSFGVK_MANAGED`
- Manifest: `VkLayer_LSFGVK_frame_generation.json`; Config: `~/.config/lsfg-vk/conf.toml`
- **Auto-Update**: Wird bei `nix flake update` (dokumentierter Update-Weg, README) mit allen Inputs aktualisiert — holt dann den neuesten master-HEAD und pinnt ihn neu im flake.lock

### Lizenz
- **CC BY-NC-ND 4.0** (nicht GPLv3). Eigenbau für persönliche Nutzung erlaubt; Redistribuierung/Derivate verboten. Daher Selbstbau aus offizieller Quelle, kein Community-Flake (lizenzverletzend)

### Build-Fix: Clang statt GCC (WICHTIG, 2026-08-27)
- **Problem**: Build bricht mit GCC (stdenv-Default) an `hooks.cpp:343` (`ambiguous overload for 'operator='`, `vk::Extent2D` bei brace-`operator=`) sowie `wrapper.cpp:193` (`m_syncSemaphore`)
- **Ursache**: GCC-abhängige vulkan-hpp-Mehrdeutigkeit. Der gleiche Quellcode baut in der offiziellen CI (Prebuild `lsfg-vk-2.0.0-rc1.r2.g60c7a5b` = genau master-HEAD `60c7a5b`) → **kein Code-Fehler, sondern Compiler-Problem des lokalen stdenv**
- **Lösung**: `stdenv = pkgs.llvmPackages.stdenv;` (Clang, Default-LLVM von nixpkgs, aktuell v21; NICHT extra gepinnt auf _19). Verifiziert: System-Build end-to-end EXIT=0
- **Modul**: `modules/system/lsfg-vk-dev.nix` (importiert in `hosts/nex/configuration.nix`)

### DLL-Abhängigkeit (Steam, 2026-08-28)
- lsfg-vk ist nur der Vulkan-Layer; der Frame-Gen-Algorithmus steckt in der DLL aus der **Steam-Installation von Definite Lossless Scaling**
- `lsfg-vk-cli benchmark` → `Unable to find lsfg-vk.dll` = erwartet, solange die DLL fehlt/alt ist
- **Lösung (User-Befund)**: In Steam bei Lossless Scaling den **Beta-Zweig** wählen — die Standard-Version hat noch die alte DLL, der Beta-Zweig liefert die neue `lsfg-vk.dll`
- **Verifiziert (2026-08-28)**: Benchmark läuft — 6368 Iterationen/10s, Base 636.80 fps → Output 1273.60 fps. Umzug funktional abgeschlossen

## Bekannte Probleme

### ASUS RT-AXE7800: Ping-Spikes + Download-Einbruch bei Volllast (2026-08-13, Ursache ungeklaert)
- **Problem**: Vollgas-Download über WLAN (1 Gbit) führt zu Ping-Explosionen (3000ms+) zum Router und Download bricht ein
- **Ursache ursprünglich vermutet**: AX210-Treiber/Firmware — `bt_coex_active=0`, Kernel-Wechsel, `11n_disable=8` getestet, alles ohne Erfolg
- **Theorie (nicht bestaetigt)**: ASUS Router Firmware-Bug — `Broadcom Packet Flow Cache` (Archer Hardware-Offload) crasht bei Volllast
  - **Router-Log**: `[ERROR archer] archer_ucast_common_flow_set,413: Invalid ENET-WAN source`
  - **Trigger vermutet**: `igs: Unknown symbol emfc_mfdb_ipv6_membership_add` — IPv6-Multicast-Treiber in ASUS Firmware
  - **Wichtig**: War am Ende **nicht schluessig belegt** — bleibt eine Vermutung, keine bewiesene Ursache
- **Workarounds getestet (alle erfolglos)**:
  - `bt_coex_active=0` (wird von iwlmvm ignoriert)
  - Kernel-Wechsel: Xanmod → Standard-Latest
  - Router-Reboot + Multicast-Routing deaktiviert
  - `11n_disable=8` (war nie aktiv, nur zum Test)
- **Damaliger Umweg**: ASUS als **Access Point** (AP-Modus) statt Router
  - FritzBox übernimmt NAT/Routing/DHCP (192.168.178.1)
  - Erste Tests: Ping stabil bei Volllast
- **Aktuell (2026-08-16)**: ASUS ist wieder vollwertiger Router (192.168.50.1), FritzBox raus. Notebook-WLAN läuft **wieder problemlos** — echte Ursache des frueheren Problems ist weiterhin ungeklaert

### Netzwerk-Architektur (2026-08-16, aktuell)
- **ASUS RT-AXE7800** (192.168.50.1): wieder **vollwertiger Router** — NAT, DHCP, DNS, Firewall, WLAN
  - ASUS-Router-DNS-Filter aktiv (fuer andere Geraete im Netz)
  - WiFi 6E (6GHz) + WiFi 6 (2.4/5GHz)
  - FritzBox ist wieder raus aus dem Routing
- **NixOS DNS**: Router-DNS via DHCP (NixOS-Defaults). Resolved verwaltet DNS, Router ist mDNS-Responder.
- **DNS-Hinweis 2026-08-17**: Mullvad DoT musste aufgegeben werden. Steam's steamwebhelper blockiert Port 5353 (mDNS-Multicast) — kein lokaler mDNS-Responder funktioniert wenn Steam laeuft (bekanntes Valve-Problem, betrifft sogar SteamOS). Router als DNS = Router als mDNS = kein Konflikt. Mullvad unterwegs spaeter per VPN loesen.
- **Hinweis**: Archer-Bug-Lösung (AP-Modus) war nur temporär; ASUS übernimmt wieder alle Router-Aufgaben

### AX210 Hardware-Upgrade-Plan (Backup)
- **Ziel**: Volle Performance + stabile Latenz unter Linux, ohne Treiber-Workarounds
- **Empfohlene Karte**: MediaTek MT7922 (M.2 2230) oder AMD RZ616 (rebadged MT7922)
  - Treiber: `mt7921e` (Kernel 5.16+, aktiv gepflegt von MediaTek)
  - WiFi 6E, 160 MHz, Bluetooth integriert
  - Linux-Support deutlich besser als AX210
- **Alternative**: USB-Stick mit MT7921AU-Chip (z.B. TP-Link Archer TX20U) für Plug & Play
- **Preis**: ~20-40€, Einbau: 1 Schraube M.2 2230
- **Status**: Nicht dringend, aber als Plan B festhalten

### SteelSeries GameDAC: USB-Port-Problem (2026-08-18)
- **Problem**: GameDAC (1038:1282) stuerzt bei Bidirektional-Wechsel (Mic-Aktivierung) an internen USB-A Ports ab
- **Symptom**: Beide Audio-Outputs gehen stumm, USB-Device wird komplett neu enumeriert (~8 Sek.Ausfall)
- **Ursache**: GameDAC-Firmware löst USB-Reset aus beim Mode-Wechsel (Output-only → Bidirektional). Der Genesys-Logics-Hub (05e3) an Port 2 propagiert den Reset auf alle Downstream-Geraete
- **USB-Topologie nex**:
  - Port 1 (TI Hub 12M, direkt): GameDAC funktioniert NICHT (Hub-Reset bei Mic)
  - Port 2 (Genesys 480M → TI 12M): GameDAC funktioniert NICHT (Hub-Reset propagiert)
  - **USB-C hinten**: Funktioniert einwandfrei (kein problematischer Hub im Pfad)
  - Externer USB-Hub: Funktioniert ebenfalls (anderer Hub-Chip)
- **Lösung**: GameDAC muss an USB-C angeschlossen werden (Adapter nötig, USB-A auf USB-C)
- **Hinweis**: Das Problem ist laptop-spezifisch (interne Hub-Topologie). An Desktop-PCs mit direkten USB-Ports dürfte es nicht auftreten

## Noctalia v5

### GTK-Theme-Anbindung (GTK4)
- Noctalia generiert bei Login den GTK4-Farbkatalog `~/.config/gtk-4.0/noctalia.css` (`@define-color`-Variablen)
- `gtk.css` lädt: `noctalia.css` (Farben) → `libadwaita-tweaks.css` (optische Tweaks, gewinnt bei Konflikten)
- Tweaks-Hook: `home/mortiferus/config/gtk-4.0/libadwaita-tweaks.css` (Headerbar-Glas via Umbriel-Blur, Backdrop-Dim, Nautilus-Sidebar-Radius). Kein Rebuild nötig (Bind-Mount)
- 2026-08-31: `libadwaita.css`-Import entfernt (redundant zu noctalia.css) → Theme-Parser-Warnungen bei Nautilus/Loupe weg

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

## Umbriel (Wayland-Compositor, seit 2026-08-30)

### Session & Paket
- Paket: **nixpkgs** `pkgs.umbriel` (PR #555208) → `umbriel-0-unstable-2026-08-25`, Source-Rev `af351dfa7564eaa0e73d215d057eb0b209cba057`, Binaries aus `cache.nixos.org`
- Start: `start-umbriel` (.desktop) → `umbriel.service` → `umbriel-session.target` (BindsTo graphical-session.target). Units kommen aus dem nixpkgs-Modul (`programs.umbriel.enable = true`)
- `general.autostart` bewusst NICHT gesetzt (kein Doppelstart, da noctalia.service über graphical-session.target läuft)
- XWayland: `xwayland-satellite` im PATH, Umbriel startet es selbst (`general.xwayland = true`) — kein separater service
- Beide Hosts via `system/common.nix` (importiert ebenfalls `desktop/niri.nix` mit `enable = false`)

### Config — live == Repo (Bind-Mount)
- `hosts/<host>/config-mounts.nix`: `home/<user>/config/umbriel` → `~/.config/umbriel` (systemd.mounts). Änderung im Repo = sofort live, kein Rebuild nötig
- Struktur: `config.toml` mit `[include] files = ["cfg/*.toml"]` (`appearance`, `display`, `input`, `keybinds`, `layout`, `rules`)
- `cfg/.../noctalia.toml` wird von Noctalia beim Login neu geschrieben (Farben/Theme) — nicht manuell editieren
- **Auto-Reload** bei Dateiänderung (Watcher). Prüfen: `journalctl --user -u umbriel | rg 'config reloaded'` — `sections: <x>` zeigt was sich geändert hat, `sections: none` = nichts Neues

### Diagnose (WICHTIG)
- `umbriel validate` → `config: ok` = sauber. Zeigt auch unbekannte Config-Keys.
- **Unbekannte Keys erscheinen NICHT im Journal** — nur im Start-Banner bzw. `umbriel validate`. Nach Config-Edits immer selbst validieren, das Journal allein reicht nicht!
- Verbindliche Action-Liste: `umbriel msg --help` (der laufenden Version); weitere CLI: `umbriel layers`, `umbriel windows`, `umbriel outputs`
- **Actions-Namen können zwischen Builds wechseln**: main-Doku nutzt `column-*`, Build 2026-08-25 nutzt `window-*` → siehe `umbriel.md`

### Stand (2026-08-31)
- Beide Hosts `validate → config: ok`, sauberer Start ohne Warning-Banner
- **niri komplett entfernt** (Modul/Flake-Input/Cache/Mounts; Configs unter `archive/`)
- Optik: **Blur global** via Catch-all-Regel (`[[window_rule]] blur = true`; sichtbar nur bei transparenten Fenstern), Opacity 0.95 für Discord/Steam/Legcord, kitty 0.9
- **VRR**: nur noch pro Fenster («`window_rule.vrr`», Werte `disabled|always|fullscreen`) – `output.eDP-1.vrr = "disabled"`. Globales VRR war Flacker-Ursache auf Electron-Fenstern (Zen)
- Zen-/Discord-Flackern: durch globales VRR verursacht → mit Output-`disabled` weg; Blur selbst verursachte kein Flackern
- Keybinds u.a. `Mod+Wheel` = Workspace-Wechsel, `Mod+Shift+Wheel` = Fenster in andere Workspace
- Numlock: aktuell aus beim Start (Feature fehlt im Build → `umbriel.md`)
- `xdg.desktop-portal-gtk` bleibt nötig: umbriel-portal deckt nur ScreenCast/Screenshot ab (siehe `desktop/umbriel.nix`)

### Native Wayland & Workspace-4-Regeln (2026-09-03)
- **Verifikation** `umbriel windows --json` (XWayland, ohne PROTON_ENABLE_WAYLAND):
  - `app_id = steam_app_2828860`, `content_type = "none"`, `xdg_tag = ""`, `xwayland = true`
  - → `content_type`/`xdg_tag`-Matches greifen bei XWayland/Proton **nicht** (nur `app_id = ^steam_app_.*$` funktioniert)
- **`PROTON_ENABLE_WAYLAND=1 %command%`** (Proton-Laufzeitoption pro Spiel, nativer Wayland-Treiber statt XWayland):
  - `app_id = foreverwinter-win64-shipping.exe`, `content_type = "game"`, `xdg_tag = "proton-game"`, `xwayland = false`
  - → `content_type`/`xdg_tag` greifen jetzt korrekt
  - **Risiko**: Steam Overlay kaputt, experimentell, manche Spiele mögen es nicht → nur pro Spiel setzen, nicht global
- **Window-Rules beide Hosts** (`cfg/rules.toml`, Workspace 4):
  - `content_type = "game"` → `default_workspace = 4` + `vrr = "always"` (native Wayland)
  - `xdg_tag = "^proton-game$"` → Match-Anker für native Wayland-Proton-Spiele (erweiterbar, z.B. HDR)
  - `app_id = "^steam_app_.*$"` → Fallback für XWayland-Spiele (ohne PROTON_ENABLE_WAYLAND) + `default_workspace = 4` + `vrr = "always"`
  - `app_id = "^gamescope$"` → `default_workspace = 4` + `vrr = "always"`
  - `pathofexilesteam.*`-Regel entfernt (redundant, wird von `steam_app_.*` abgedeckt)
  - **Kein `default_fullscreen`** in den Spiel-Regeln → Spiele starten getilted auf W4, anderes Fenster (z.B. Build-Planer) kann daneben getiled werden

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

**Problem**: Cursor-Theme (Bibata-Modern-Ice) in Steam nicht überall sichtbar (gelöst 2026-08-20)
- **Ursache**: Steam's CEF-Teil (steamwebhelper, Chromium-basiert) nutzt GTK für Cursor-Rendering. `XCURSOR_THEME` reicht für native X11/Wayland-Apps, CEF/Chromium liest aber GTK-Settings (`~/.config/gtk-3.0/settings.ini`).
- **FHS-Sandbox-Problem**: Home-Manager legte `~/.config/gtk-3.0` als Symlink auf `/etc/nixos/...` an. Im Steam-FHS-Sandbox (bubblewrap) war `/etc` ein tmpfs → Symlink kaputt → CEF fand `settings.ini` nicht.
- **Lösung (final)**: `~/.config/gtk-3.0` wird jetzt als system-level Bind-Mount bereitgestellt (`hosts/nex/config-mounts.nix`). Die Config-Datei liegt direkt am erwarteten Pfad, kein Symlink-Auflösung nötig → CEF findet `settings.ini` in der FHS-Umgebung. `extraProfile`-Hack in `steam.nix` und `autostart.nix` wurde entfernt.

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

## Heroic / Lutris / UMU (RDR2 Epic, 2026-08-29)

### RDR2 (Epic) über Heroic — Status: läuft
- Läuft über den offiziellen `fix.bat`-Workaround (UMU aktiv, Patches erhalten), **nicht** deklarativ in Nix:
  1. fake `EpicGamesLauncher.exe` (heroic-epic-integration, von Heroic gebündelt) ins Spielverzeichnis kopieren (neben `PlayRDR2.exe`)
  2. `fix.bat` anlegen: `start "" EpicGamesLauncher.exe PlayRDR2.exe %*` (CRLF-Zeilenende!)
  3. In Heroic "Alternative EXE" (`targetExe` in `GamesConfig/Heather.json`) auf `fix.bat` setzen
  4. `USE_FAKE_EPIC_EXE=true` als Env-Variable
- Die fake `EpicGamesLauncher.exe` macht **zwei** Dinge (`main.c`):
  1. `SetEnvironmentVariable("SteamAppId", NULL)` → entfernt SteamAppId → kein Steam-Check
  2. startet `PlayRDR2.exe` als Parent-Prozess → RGL erkennt Epic → Ownership ok
- Achtung: bei Heroic-Update/Game-Reinstall muss `fix.bat` + `targetExe` ggf. neu angelegt werden.

### UMU SteamAppId-Injektion (Root-Cause des Steam-Checks)
- `umu-launcher` injiziert `SteamAppId=<numerisch>` aus `GAMEID=umu-<numerisch>` (`umu_run.py set_env`): RDR2 → `GAMEID=umu-1174180` → `SteamAppId=1174180`
- **Beabsichtigt** (umu-database: numerische Steam-ID, damit Valve-Proton-Fixes auf Nicht-Steam-Versionen wirken)
- Rockstar-Launcher liest `SteamAppId` → "Steam konnte nicht initialisiert werden" (wenn kein Steam läuft)
- Passiert auf **allen** Distros (identischer Code in nixpkgs 1.4.4 und GitHub main) → **kein NixOS-spezifisches Problem**

### USE_FAKE_EPIC_EXE (Automatik) kaputt — überall, nicht nur NixOS
- Heroics `USE_FAKE_EPIC_EXE` setzt `LEGENDARY_WRAPPER_EXE=C:\windows\command\EpicGamesLauncher.exe`
- **Aber**: `legendary-gl` 0.21.0 hat `LEGENDARY_WRAPPER_EXE` **nicht** (nur `LGDRY_WRAPPER` für `--wrapper`)
- Heroic bündelt selbst `legendary-gl` 0.21.0 (`meta/downloadHelperBinaries.ts`, `RELEASE_TAGS.legendary = '0.21.0'`) — nixpkgs bündelt **dasselbe** → **kein falscher Fork**
- Folge: Automatik greift nicht, `PlayRDR2.exe` startet direkt → Steam-Check + Ownership beide kaputt
- Der `fix.bat`-Weg ist die offizielle, auf allen Distros nötige Lösung (Wiki "Rockstar Games from Epic Games")

### Lutris (RDR2) — offen
- Gleiche UMU-SteamAppId-Injektion, aber **kein** fake-`EpicGamesLauncher.exe`-Mechanismus
- Steam-Check bleibt bestehen. Fix-Optionen (nicht umgesetzt):
  - `UMU_ID=0` + `SteamAppId=0` (bisheriger Workaround, verliert UMU-Patches)
  - lokale protonfixes-Gamefix `~/.config/protonfixes/localfixes/umu-1174180.py` mit `util.del_environment('SteamAppId')` / `del_environment('SteamGameId')`
- Nicht priorisiert (Heroic reicht zum Spielen)

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
- `attic.xuyh0120.win/lantian` – CachyOS Kernel Binaries (Flake-Input: `github:xddxdd/nix-cachyos-kernel/release`)

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
- **nex**: `boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest` (seit 2026-08-20, vorher `linuxPackages_zen`)
  - CachyOS Kernel via [xddxdd/nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel) (pinned Overlay + Binary Cache)
  - `scx_bpfland` **deaktiviert** — CachyOS-Kernel wird pur getestet
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

## Audio / ChatMixer

### GameDAC Custom ALSA Profile (2026-08-27, final)
- **Ansatz**: ALSA Card Profile (ACP) aus [rockofox/steelseries-gamedac-pulseaudio](https://github.com/rockofox/steelseries-gamedac-pulseaudio), angepasst und in NixOS-Config integriert
- **Warum ACP**: PipeWire nutzt ACP (`api.alsa.use-acp = true`) als Back-End. Es gibt kein PipeWire-native Äquivalent — ACP ist der einzige Layer der ALSA-Karten Channel-Mappings und Profile zuweisen kann
- **Warum nicht Loopback**: Loopback routete auf AUX0-AUX5 (non-standard Names). Wine/Proton erwartet FL FR FC LFE RL RR. Das ACP-Profile gibt dem GameDAC korrekte Channel-Names am PulseAudio-Layer
- **Implementation** (`modules/hardware/audio.nix`, `environment.etc`):
  - Profile-Set: `steelseries-gamedac-usb-audio.conf` (Chat + Game + Mic Mappings)
  - Path-Files: `steelseries-gamedac-output-game.conf`, `...-chat.conf`, `...-input.conf`
  - WirePlumber-Config: `51-gamedac-profiles.conf` (setzt `device.profile-set` + `device.profile`)
  - **Kein `volume = merge`** — GameDAC ALSA-Mixer hat nur Mute-Switches, kein Volume-Control. Ohne `merge` setzt PipeWire 100% als Software-Default
- **Default-Sink**: `alsa_output.usb-SteelSeries_SteelSeries_GameDAC_000000000000-00.analog-game`
- **Nach Rebuild**: Files stehen in `/etc/alsa-card-profile/...` + `/etc/wireplumber/...` (systemweit, survives Reinstall)
- **pavucontrol**: Unterhaltung-Ausgabe + Spiel-Ausgabe + Mic-Eingang (nicht Pro-Audio)

### Alte Ansätze (verworfen)
- ~~5.1 Loopback~~ (`gamedac-5.1.conf`) — Channel-Names AUX0-AUX5, Proton erkannte nur Stereo
- ~~Pro-Audio Profil~~ — Kanäle nicht korrekt gemappt, Channel-Namen falsch
- ~~HeSuVi / Virtual Surround~~ — GameDAC DSP macht räumliches Audio aus Stereo-Eingang
- ~~Artenic-ASM / Software-ChatMix~~ — GameDAC hardwareseitig besser (separate Outputs)

### ChatMixer (deaktiviert 2026-08-18)
- **Kein Software-Chatmix mehr nötig** — GameDAC bietet hardwareseitig zwei separate Ausgänge
- **ChatMixer-Config deaktiviert** (`.conf.disabled`), da GameDAC die Trennung hardwareseitig übernimmt

### LADSPA_PATH Fix (NixOS pipewire-Modul Bug)
- Das NixOS `pipewire`-Modul setzt `LADSPA_PATH` hardcoded auf `${pkgs.pipewire.ladspa-plugins}/lib/ladspa` — dieses Paket ist **leer**.
- **Fix**: `systemd.user.services.pipewire.environment.LADSPA_PATH = lib.mkForce "${pkgs.ladspaPlugins}/lib/ladspa";` in `audio.nix`.
- `lib.mkForce` ist noetig, weil das NixOS-Modul den gleichen Option-Pfad definiert und sonst ein Konflikt entsteht.

### GameDAC stabil halten – Liedwechsel-Knacken (2026-08-31)
- **Symptom**: kleines "Knacken" bei jedem Liedwechsel (als würde das Gerät neu starten), YouTube + andere Quellen
- **Signalweg**: `Zen → sonar-media-eq (LADSPA-EQ) → hesuvi-media (Virtual 7.1/HRTF-Convolution) → Downmix → GameDAC`
- **Ausgeschlossen**: USB-Autosuspend (`power/control=on`), WirePlumber-Suspend (5 s; Kette suspendet nicht), `clock.force-quantum` (1024 half nicht), ASM-`pipewire_quantum` (war 0/auto)
- **Ursache (bewiesen)**: Bei jedem Titelwechsel öffnet Chromium einen **neuen** Stream; die Kette fällt kurz in `idle` und die HeSuVi/Sonar-Convolution erzeugt beim Wiederanlaufen einen Transienten. Spatial-Audio für Media AUS → Knacken weg → Convolution ist der Übeltäter.
- **Fix (persistent, ersetzt durch Upstream 2026-09-02)**: ASM-Paket war lokal gepatcht → Filter-Ketten mit `node.pause-on-idle = false`. Die Kette pumpt im Leerlauf Stille weiter und fällt nie in `idle` → Convolution behält ihren Zustand, kein Transient. Überlebte jede ASM-Regeneration.
  - **Upstream aufgenommen in v1.4.14 (2026-09-01)**: Issue **#223** https://github.com/loteran/Arctis-Sound-Manager/issues/223 → Commit `de79748` „keep Media HeSuVi convolver warm across track changes". `node.pause-on-idle = false` nun **Media-only** (andere Kanäle behalten Idle-Suspend aus #180). In-place-Repair patcht bestehende Installs automatisch.
  - **Lokaler Patch entfernt (2026-09-02)**: `scripts/asm-pause-on-idle.py` gelöscht, `overrideAttrs` in `hosts/nex/configuration.nix` entfernt. Voraussetzung: ASM-Version ≥ v1.4.14 im Flake.
- **Erste (vorläufige) Fixes** (`51-gamedac-stable.conf` in `audio.nix`): `session.suspend-timeout-seconds = 0` auf dem GameDAC-Sink (bleibt, schadet nicht) + Rate-Pin 48k/2ch (Enum bleibt S16LE)
- **Wartungs-Falle**: verwaiste User-Unit `~/.config/systemd/user/arctis-manager.service` (Symlink auf alten Store-Pfad) überschattete die NixOS-Unit und hielt den alten Daemon am Leben → entfernt (Backup `/tmp/opencode/`). Nach Paket-Override immer prüfen, dass der Daemon auf dem neuen Pfad läuft.
- **Status**: lokal gefixt → upstream aufgenommen → lokaler Patch entfernt. Verifiziert, solange Flake auf v1.4.14+ ist.

### Files (2026-08-27)
- `modules/hardware/audio.nix` — GameDAC Profile + WirePlumber + `environment.etc` (aktiv)
- `modules/hardware/audio.nix` (`51-gamedac-stable.conf`) — Nie-Suspend + fixe hw_params (2026-08-31)
- `scripts/asm-pause-on-idle.py` — Patch für ASM-Paket (pause-on-idle in Filter-Ketten-Props) (2026-08-31)
- `home/mortiferus/config/pipewire/pipewire.conf.d/chatmixer.conf.disabled` — Game + Chat DSP Chains (deaktiviert)
- `home/backbone/config/pipewire/pipewire.conf.d/chatmixer.conf.disabled` — Game + Chat DSP Chains (deaktiviert)
- ~~`home/mortiferus/config/pipewire/pipewire.conf.d/gamedac-5.1.conf.disabled`~~ — gelöscht (2026-08-27)
- ~~`~/.config/alsa-card-profile/`~~ — user-local Files gelöscht, via `environment.etc` ersetzt (2026-08-27)
- ~~`~/.config/wireplumber/wireplumber.conf.d/51-gamedac-profiles.conf`~~ — user-local File gelöscht, via `environment.etc` ersetzt (2026-08-27)

## Installation (2026-08-15, aktualisiert 2026-08-17)

### Installer: `install.sh` (sichere Laufwerksauswahl)
- **Problem (geloest)**: Linux erkennt Laufwerke nicht immer in gleicher Reihenfolge (nvme0 vs. nvme1 vs. sda) — die Festplatte waere sonst auf der falschen Disk gelandet
- **Loesung**: Interaktive Laufwerksauswahl per `lsblk -P` mit Modell + Seriennummer + Label
  - Unterstuetzte Geraete: `nvme*`, `sd*` (SATA/SAS/USB), `vd*` (VirtIO), `hd*` (IDE), `mmcblk*` (eMMC)
  - Kein hardcoded `/dev/nvme0n1` mehr im Skript
  - Sicherheitsabfrage vor dem Loeschen (disko fragt `yes`)
  - Warnung, falls das gewaehlte Laufwerk ein Label hat (z.B. `GamingDrive` auf nex)
- **Device-Uebergabe an disko**: `--argstr device` funktioniert bei Flakes nicht zuverlaessig. Stattdessen erzeugt `install.sh` zur Laufzeit eine temporaere disko-Config (`/tmp/disko-<host>.nix`), die die host-spezifische disko-Config mit dem gewaehlten Device importiert.
- **Unterstuetzte Hosts**: `nex`, `styx`, `test`
- **Backup**: alte Version als `install.sh.legacy`

### Disko-Configs
- `hosts/nex/disk-config.nix`: `{ device ? "/dev/nvme0n1", ... }:` — Default fuer normales Rebuild, vom Installer ueberschreibbar
- `modules/system/disko-basic.nix` (styx): `{ device ? "/dev/nvme0n1", ... }:` — bereits flexibel
- `hosts/test/disk-config.nix`: `{ device ? "/dev/nvme0n1", ... }:` — fuer QEMU-Tests
- `flake.nix`: `diskoConfigurations.nex/styx/test` bleiben als Flake-Output erhalten (fuer direktes disko-CLI), der Installer nutzt sie aber nicht mehr

### QEMU-Testumgebung
- `test-installer.sh`: QEMU-VM mit 2 virtuellen NVMe-Disks + NixOS ISO
  - `./test-installer.sh iso` — baut ISO und bootet VM fuer Installer-Test
  - `./test-installer.sh vm` — baut Test-Host direkt
  - ISO wird als `packages.installer-iso` im Flake gebaut
- `hosts/test/configuration.nix`: minimaler NixOS-Host (kein Desktop, kein Home-Manager) fuer schnelle Builds

### Installer-Swap (temporaer, nur fuer die Installation)
- `install.sh` legt ein **temporaeres Swapfile** auf `/mnt/.install-swapfile` an (2x RAM, max 16G), aktiviert es per `swapon` und entfernt es via `trap cleanup_swap EXIT` nach der Installation wieder
- Swapfile landet **nie** im installierten System — disko-Configs haben weiterhin keinen Swap, System laeuft ZRAM-only
- Wenn `swapon` fehlschlaegt (z.B. in QEMU), laeuft der Installer mit Warnung weiter
