# lion-pc – Implementierungsplan (Gaming-Rechner für lion)

Zweck: Plan für den neuen NixOS-Host **lion-pc** (Gaming-Desktop, AMD CPU + AMD Radeon RX 580 8GB)
festhalten, bevor implementiert wird. Der Plan ist **noch nicht umgesetzt** — hier wird der Stand der
Entscheidungen dokumentiert. Die App-Liste ist **festgelegt** (siehe Abschnitt unten).

Referenz: `umbriel.md` (Format/Versionstracking). Host-Muster: `hosts/nex`, `hosts/styx`.

---

## Überblick

- Zweck: eigener Gaming-PC für **lion** (Kind), Roblox als Hauptspiel.
- Hardware: AMD CPU (Ryzen) + **AMD Radeon RX 580 8GB** (GCN, diskret, kein iGPU/APU-Shared-RAM).
- Basis: vorhandene Host-Struktur + CachyOS-Kernel (wie `nex`).
- DE: **Umbriel** (eigener Wayland-Compositor, wie `nex`/`styx` — **kein KDE**).
- User: **lion** / Hostname **lion-pc**.

## Wichtige Grundsatz-Entscheidungen

| Thema | Entscheidung | Begründung |
|---|---|---|
| Config-Stil | **HTTP(S)-Remote** wie `styx` (`https://github.com/...`) | Desktop ohne SSH-Key-Management; install.sh nutzt HTTPS-URL |
| SSD-Gerät | **interaktiv in install.sh wählen** | kein fixer Device-Pfad im Plan (SSD unbekannt) |
| App-Liste | **FESTGELEGT** — identische Basis wie nex (Admin/Wartungstools bleiben), komplette Gaming-Stack-Basis | notierte Abwesenheit: kein Kinder-only-Minimalsystem; Aufbau soll von hinten identisch sein (Wartbarkeit) |
| Roblox | **installiert lion selbst via Flatpak** (Sober/Vinegar) aus kinderfreundlichemStore (Bazaar) | **NICHT deklarativ**; kein eigenes Nix-Package für lion |
| eigene Nix-Pakete | **keine** für lion | nur Flatpak |
| dmemcg-VRAM (Valve-Fix) | **ausgelassen + TODO-Vermerk** | siehe unten |
| sudo auf lion-pc | **Passwort nötig** (`security.sudo.wheelNeedsPassword = true`, Override auf common) | Bazaar bleibt polkit-passwordlos, aber eine bösartige App kann nicht zu Root eskalieren; kein SSH auf dem Host → lokal unkritisch |

---

## App-Liste für lion-pc (FESTGELEGT, 2026-09)

### Grundprinzip
- Der Aufbau soll **decken-identisch** zu nex/styx sein — kein Kinder-Minimalsystem. mortiferus möchte
  sich unter lion auskennen, falls er dort was warten muss. → **common/system-Module + Basis-Pakete bleiben
  vollständig aktiv.**

### Admin-/Wartungs-Basis (bleibt deklarativ, identisch zu nex)
`neovim`, `fish`, `eza`, `jq`, `scx.full`, `ookla-speedtest`, `zoxide`, `bat`, `fzf`, `starship`,
`kitty`, `xdg-utils` — kommen komplett über die gemeinsamen Module (common/system) mit; keine Extra-Entscheidung nötig.

### Gaming-Stack (bleibt deklarativ, wie nex)
`steam`, `heroic`, `lutris`, `gamescope`, `protonplus`, `game-performance`-Skript, `vulkan-tools`,
`goverlay`, `discord`, `cartridges` — **alles bleibt drin**; lion soll fähig sein zu zocken (Steam/Epic/etc.).

### Raus für lion-pc (NICHT deklarativ installieren)
| App | Begründung |
|---|---|
| IdeaMaker | 3D-Druck (Raise3D, nex) |
| OrcaSlicer | 3D-Druck |
| PrusaSlicer | 3D-Druck |
| PathOfBuilding (`rusty-path-of-building`) | PoE-Build-Tool |
| Polychromatic | **nur Razer/OpenRazer**, kein SteelSeries → nutzlos für lion |
| Sunshine | Game-Streaming-Client/Server für nex-Kontext; nicht nötig |
| Arctis Sound Manager | nicht einbauen (kein Bedarf) |

-> Stelle sicher, dass o.g. Pakete NICHT über common/system/gaming-Module auf lion-pc landen
   (entweder Modul scharf trennen oder per Host ausschließen — bei Implementierung prüfen).

---

## dmemcg-VRAM-Optimierung (Valve / Natalie Vock) – AUSGELASSEN

### Was das ist
CachyOS-Hello's "VRAM Management"-Toggle = `dmemcg-booster` + Fokus-Booster. Priorisiert das
Vordergrund-Spiel in **VRAM** über Hintergrund-Apps, wenn der VRAM (8 GB und weniger) unter Druck
gerät — reduziert GTT-Spillover/Stutter (z. B. Cyberpunk: GTT 1.37 GB → 650 MB).

### Warum wir es NICHT einbauen
- `dmemcg-booster` ist Compositor-unabhängig (systemd-Service, aktiviert `dmem`-cgroup-Controller).
- Aber: **Vordergrund-Erkennung braucht einen Compositor-Booster**, alle existierenden sind fest an
  ihren Compositor gekoppelt: KDE (`plasma-foreground-booster`), niri (`niri-focused-booster`),
  Hyprland (`hyprland-focused-booster`), Gamescope.
- **Umbriel ist ein eigener, eigenständiger Compositor** (C++23 auf wlroots + eigenem umbrielfx;
  `git+https://github.com/noctalia-dev/umbriel`; geprüft bis Rev `5e7efc50`/`0a0591da`, 2026-09).
  → **keiner der fertigen Booster passt direkt.**
- **Umbriel hat (Stand 2026-09) KEINE eingebaute dmem/VRAM-Priorisierung** (nicht im Store-Build,
  nicht im upstream-README/Feature-Set erkennbar).
- Ein eigener Umbriel-Fokus-Booster = eigenes Kleinprojekt (IPC + dmemcg-booster) mit Wartungspflicht.
  Für 8-GB-Roblox/Sober (VRAM-modest) ist der Break-even fraglich → heute nicht gerechtfertigt.

### TODO-Vermerk (nachrüsten, wenn)
- [ ] Umbriel bekommt nativ dmem/cgroup-VRAM-Unterstützung (Projekt ist jung+aktiv, ~40 Commits/Tag),
  **oder**
- [ ] es existiert ein stabiler, wartbarer Umbriel-Fokus-Booster (eigenes Projekt oder Community),
  **und**
- [ ] es gibt einen konkreten Anlass (Roblox/Spiele treffen VRAM-Limit spürbar).
- Zusätzlich nötig: Kernel-Teil (dmem-Patches) ist im CachyOS-Kernel ≥ 7.0rc7-2 enthalten — abgedeckt,
  sobald CachyOS-Kernel für lion-pc läuft. `dmemcg-booster` müsste dann als eigenes Nix-Package gebaut werden.

### Was wir STATTDESSEN tun (Basissetup)
- `vm.max_map_count = 16777216` (aus `boot-nex.nix`) — relevant für VRAM-Mapping (GCN/RADV), GPU-unabhängig.
- Normale AMD-GPU-Konfiguration (amdgpu/Mesa, kvm-amd, Microcode) — deckt Roblox/Sober voll ab.

---

## Zu erstellende Dateien (Implementierung, noch nicht umgesetzt)

### Neue Module
- `modules/hardware/amdgpu.nix` — Template `modules/hardware/intel.nix`
  - `hardware.graphics.enable = true; hardware.graphics.enable32Bit = true;`
  - Vulkan-Pakete für Mesa/RADV
  - `services.xserver.videoDrivers = lib.mkForce [ "amdgpu" ];`
  - KEINE NVIDIA-/Intel-Cache-Env
- `modules/system/boot-lion.nix` — Template `modules/system/boot-nex.nix`
  - `imports = [ ./boot-common.nix ];`
  - CachyOS-Kernel Overlay (xddxdd) + `boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest`
  - `amd_pstate=active`; Blacklist `esp4 esp6 rxrpc algif_aead iTCO_wdt sp5100_tco`
  - `vm.max_map_count = 16777216`; ZRAM
- `modules/system/environment-lion.nix` — Template `modules/system/environment-nex.nix`
  - `imports = [ ./environment-common.nix ];`
  - Entfällt: NVIDIA-Cache-Env; `nixpkgs.config.cudaSupport = false`

### Host `<name>`
- `hosts/lion-pc/hardware-configuration.nix` — **vorkonfiguriert** (install.sh generiert KEINE)
  - `boot.initrd.kernelModules = [ "kvm-amd" ];` → `boot.kernelModules = [ "kvm-amd" ];`
  - `hardware.cpu.amd.updateMicrocode = true;`
  - generische `fileSystems` (ESP + ext4, ZRAM-only), Template `hosts/nex/hardware-configuration.nix`
- `hosts/lion-pc/configuration.nix` — imports:
  - `./hardware-configuration.nix`, `./disk-config.nix`
  - `../../modules/system/common.nix`, `../../modules/system/boot-lion.nix`, `../../modules/system/environment-lion.nix`
  - `../../modules/hardware/amdgpu.nix`
  - `../../modules/programs/gaming`, `../../modules/programs/cachyos-tools.nix`, `../../modules/programs/tools.nix`, `../../modules/programs/editor.nix`, `../../modules/programs/shell.nix`, `../../modules/programs/terminal.nix`
  - `../../modules/users/lion.nix`, `../../modules/home/lion` (falls home-manager)
  - `networking.hostName = "lion-pc";`
  - **`security.sudo.wheelNeedsPassword = lib.mkForce true;`** — Override der common.nix-Vorgabe
    aus security.nix (`false`): sudo-Passwort auf lion-pc nötig, damit bösartige Flatpak-Apps
    nicht zu Root eskalieren können (Bazaar/Flatpak bleibt via Polkit passwordlos)
- `hosts/lion-pc/disk-config.nix` — Template `disko-basic.nix` (ext4 + ESP, ZRAM-only), SSD-Device interaktiv
- `hosts/lion-pc/config-mounts.nix`

### User / Home
- `modules/users/lion.nix` — User **lion** (users-Gruppe, etc.)
- Home für lion via home-manager: **Umbriel-Config 1:1 von nex/mortiferus übernehmen** (Umbriel + Noctalia-Einstellungen identisch, da alltagstauglich); nur Host-Anpassungen

### flake.nix
- `nixosConfigurations."lion-pc"` Eintrag ergänzen (gleiche Struktur wie nex/styx)

### install.sh
- Menü erweitern: `4) lion-pc (Gaming-PC / lion)`
- `HOSTNAME="lion-pc"`, `USERNAME="lion"`
- Disk-Device-Auswahl (interaktiv, kein fester Pfad)
- HTTPS-Remote-URL (`https://github.com/xXMortiferusXx/nix-config.git`, wie styx)

---

## Flatpak + Bazaar + Roblox (nur lion-pc)

### Bazaar – App-Store als nixpkgs-Package (nicht Flatpak)
- **`pkgs.bazaar` existiert in nixpkgs** (Version 0.9.1, "FlatHub-first app store for GNOME").
- Bazaar wird **deklarativ als natives nixpkgs-Package** installiert (`environment.systemPackages`),
  nicht über Flatpak — damit ist es Teil des Systems und wird beim `switch` mit aktualisiert.
- Bazaar ist der **Store-Client**; um damit Apps zu installieren, braucht lion-pc trotzdem die
  Flatpak-Infrastruktur (unten) — beides kommt zusammen.
- **GNOME-Abhängigkeiten (gtk4/libadwaita):** nicht explizit systemweit gelistet, aber **real verifiziert vorhanden**
  (transitiv via bereits installierter GTK4-Apps; im Current-System und Store: `gtk4-4.22.4`, `libadwaita-1.9.3`).
  `adw-gtk3` im Repo ist **GTK3**, nicht libadwaita. → Bazaar fügt keinen nennenswerten zusätzlichen
  Abhängigkeits-/Build-Aufwand hinzu; gtk4/libadwaita sind schon im System.

### Auto-Update (der eigentliche "eigenständig updaten"-Punkt)
- Bazaar selbst updated sich über `nixos-rebuild` (nixpkgs-Package).
- Die **Flatpak-Apps, die lion installiert (Roblox=sober, etc.) aktualisieren sich NICHT von alleine.**
  → **systemd-Timer `flatpak-update` deklarativ** einrichten (regelmäßig `flatpak update`), damit
  lions Spiele/Apps eigenständig up-to-date bleiben.

### Flatpak-Infrastruktur (Basis für Bazaar + Roblox)
- Flatpak ist aktuell **NIRGENDS** im Repo aktiviert → für lion-pc deklarativ:
  - `services.flatpak.enable = true;`
  - Flathub-Remote (deklarativ)
- **Basis:** `modules/system/cachyos-tuning.nix` setzt bereits `kernel.unprivileged_userns_clone = 1` (Flatpak-Sandbox).
- **nex bleibt OHNE Flatpak** (nur optional für Tests).

### Roblox (Install durch lion selbst, nicht deklarativ)
- `org.vinegarhq.Sober` (Player) + `org.vinegarhq.Vinegar` (Studio) via Flatpak/Bazaar
- RX 580 (GCN) funktioniert gut mit Mesa/RADV für Roblox

---

## Verifikation (nach Implementierung)

1. `nix-instantiate --parse` auf allen neuen Dateien
2. `nix build '.#nixosConfigurations.lion-pc.config.system.build.toplevel'`
3. install.sh-Logik (Menü/Remote/Device) prüfen
4. Flatpak/bazaar-Verfügbarkeit prüfen

---

## Offene Punkte (TODO)

- [ ] **Bazaar/Flatpak-Setup UMSETZEN** (Konzept entschieden, 2026-09): Bazaar = nixpkgs-Package
(`pkgs.bazaar`, wird per `nixos-rebuild` mitgeupdatet) + Flatpak-Infrastruktur + Flathub deklarativ.
  lion installiert eigenständig über Bazaar; seine **Flatpak-Apps** (Roblox=Sober, etc.) aktualisiert der
  deklarative `flatpak-update`-systemd-Timer (und Bazaar kann zusätzlich updaten).
  **Scope gelöst:** kein `--user`-Scope — Flatpak-Polkit-Regel für wheel (polkit.nix) macht systemweite
  Installation passwordlos; sudo-Trennschicht (Passwort) bleibt als Eskalationsblockade.
  **Erwartung:** Bazaar zeigt ganzes Flathub (kein Altersfilter) —
  "kinderfreundlich" = einfacher für lion als CLI.
- [ ] **Gaming/App-Module scharf auf lion-Packung prüfen** — sicherstellen, dass Raus-Apps (IdeaMaker,
  OrcaSlicer, PrusaSlicer, PathOfBuilding, Polychromatic, Sunshine, Arctis) NICHT via gemeinsamen Modulen
  auf lion-pc landen (Modul-Trennung vs. Host-Ausschluss).
- [ ] **User/Home lion**: Umbriel-Config → **1:1 von nex übernehmen** (Config von nex/mortiferus ist alltagstauglich und wird übernommen — Umbriel + Noctalia-Einstellungen identisch). Nur host-spezifische Anpassungen wenn unbedingt nötig.
- [ ] dmemcg nachrüsten (siehe TODO oben)
