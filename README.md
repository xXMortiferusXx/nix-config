# Mortiferus NixOS Configuration

This is my personal NixOS flake managing two machines with a shared module system.

## Hosts

| Host | Hardware | Role |
|------|----------|------|
| **nex** | AMD Ryzen + NVIDIA RTX (NVIDIA-only mode), Lenovo Legion Laptop | Gaming / Desktop |
| **styx** | Intel Laptop | Office / Work |

Both share a common base via `modules/system/common.nix` – only hardware-specific and role-specific modules differ per host.

## Quick Start

```bash
# Build / switch for a host
sudo nixos-rebuild switch --flake .#nex
sudo nixos-rebuild switch --flake .#styx

# Update flake inputs
nix flake update
```

## Structure

```
flake.nix              # Inputs (nixpkgs, home-manager, disko, noctalia, ...)
hosts/
├── nex/               # Gaming laptop config + disko partitioning
└── styx/              # Office laptop config + disko partitioning
modules/
├── desktop/           # Compositor (umbriel), greeter, polkit, fonts
├── hardware/          # GPU drivers, audio, laptop features, legion, touchpad
├── home/              # Home-Manager per user (mortiferus + backbone)
├── programs/          # Gaming stack, tools, shell, terminal, editor, zen-browser
├── services/          # Noctalia (desktop shell), printing
├── system/            # Boot, kernel, tuning, networking, nix-settings
└── users/             # User definitions
home/                  # Raw dotfiles (linked via home-manager xdg.configFile)
memory.md              # Dev notes (current state, IPC commands, systemd services)
umbriel.md             # Umbriel version/feature tracker (upstream dev watch)
```

### Design Principle

One file = one topic. Large files get split into submodules (e.g., `programs/gaming/` contains `steam.nix`, `lutris.nix`, `gamescope.nix`, …).

## Key Technologies

- **NixOS** (unstable channel) with **flakes**
- **Home Manager** for per-user dotfiles and services
- **Disko** for declarative partitioning
- **Noctalia v5** as desktop shell (launcher, notifications, clipboard, …)
- **Umbriel** (wlroots-based Wayland compositor) directly from the Umbriel flake (`inputs.umbriel`) as the only session; niri and Hyprland are removed (configs archived under `archive/`)
- **CachyOS** kernel (`cachyos-latest`) on nex via [xddxdd/nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel) with `attic.xuyh0120.win/lantian` binary cache. CachyOS-derived sysctl/udev/PAM/bpftune tuning
- **ananicy-cpp** with [CachyOS rules](https://github.com/CachyOS/ananicy-rules) for automatic per-process nice/ionice/sched prioritization
- **Cachix**: `noctalia.cachix.org` for pre-built Noctalia binaries
- **PipeWire** audio with low-latency config

## Desktop / Compositor

Both hosts use Noctalia as the shell (started via `systemd --user`). The login manager is the Noctalia Greeter; Umbriel registers the session itself via its `.desktop` entry. All user services (Discord, Steam, udiskie, …) run as `systemd.user.services`.

### Noctalia IPC Commands

Used for keybind shortcuts. Example: `noctalia msg spotlight toggle`, `noctalia msg clipboard toggle`, `noctalia msg lockscreen lock`.

See `memory.md` for the full list.

## Gaming (nex only)

nex runs in **NVIDIA-only mode** (no iGPU/PRIME offloading) for maximum dGPU performance. It has a dedicated gaming module stack:

- Steam (with Proton-GE, hardware decoding)
- Lutris (custom wrapper with steam-run)
- Gamescope session
- Sunshine (streaming)
- Lossless Scaling FG Vulkan layer (built from `git.lsfg-vk.dev`, auto-updates with `nix flake update`; needs the Steam version's DLL via the Beta branch)
- MangoHud
- DLSS Swapper / Zink wrappers

Plus a dedicated `/gaming` partition (ext4) on a separate NVMe.

## Acknowledgements

- [Noctalia](https://github.com/noctalia-dev/noctalia) – desktop shell
- [Noctalia Greeter](https://github.com/noctalia-dev/noctalia-greeter) – login manager
- [Umbriel](https://github.com/noctalia-dev/umbriel) – wlroots-based Wayland compositor
- [bpftune](https://github.com/oracle/bpftune) – BPF-driven network auto-tuning (Oracle)
- [CachyOS](https://github.com/CachyOS) – kernel tuning inspiration
- [CachyOS ananicy-rules](https://github.com/CachyOS/ananicy-rules) – process priority rules
- [xddxdd](https://github.com/xddxdd) – [nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel) with pre-built CachyOS kernels and binary cache
- All the NixOS community for endless inspiration

---

# 🇩🇪 Mortiferus NixOS Konfiguration

Meine persönliche NixOS-Flake, die zwei Rechner mit einem gemeinsamen Modulsystem verwaltet.

## Hosts

| Host | Hardware | Rolle |
|------|----------|-------|
| **nex** | AMD Ryzen + NVIDIA RTX (NVIDIA-only Modus), Lenovo Legion Laptop | Gaming / Desktop |
| **styx** | Intel Laptop | Büro / Arbeit |

Beide teilen sich eine gemeinsame Basis via `modules/system/common.nix` – nur hardware- und rollenspezifische Module unterscheiden sich.

## Schnellstart

```bash
# Build / Switch für einen Host
sudo nixos-rebuild switch --flake .#nex
sudo nixos-rebuild switch --flake .#styx

# Flake-Inputs aktualisieren
nix flake update
```

## Aufbau

```
flake.nix              # Inputs (nixpkgs, home-manager, disko, noctalia, ...)
hosts/
├── nex/               # Gaming-Laptop Konfig + Disko Partitionierung
└── styx/              # Büro-Laptop Konfig + Disko Partitionierung
modules/
├── desktop/           # Compositor (umbriel), Greeter, Polkit, Fonts
├── hardware/          # GPU-Treiber, Audio, Laptop-Features, Legion, Touchpad
├── home/              # Home-Manager pro User (mortiferus + backbone)
├── programs/          # Gaming-Stack, Tools, Shell, Terminal, Editor, Zen-Browser
├── services/          # Noctalia (Desktop-Shell), Drucken
├── system/            # Boot, Kernel, Tuning, Netzwerk, Nix-Settings
└── users/             # Benutzerdefinitionen
home/                  # Rohe Dotfiles (via home-manager xdg.configFile verlinkt)
memory.md              # Entwickler-Notizen (aktueller Stand, IPC, systemd)
umbriel.md             # Umbriel-Versions-/Feature-Tracker (Upstream-Entwicklung)
```

### Design-Prinzip

Eine Datei = ein Thema. Große Dateien werden in Untermodule aufgeteilt (z.B. `programs/gaming/` enthält `steam.nix`, `lutris.nix`, `gamescope.nix`, …).

## Wichtige Technologien

- **NixOS** (unstable-Channel) mit **Flakes**
- **Home Manager** für User-Dotfiles und -Services
- **Disko** für deklarative Partitionierung
- **Noctalia v5** als Desktop-Shell (Launcher, Notifications, Clipboard, …)
- **Umbriel** (wlroots-basierter Wayland Compositor) direkt vom Umbriel-Flake (`inputs.umbriel`) als einzige Session; niri und Hyprland sind entfernt (Configs unter `archive/`)
- **CachyOS**-Kernel (`cachyos-latest`) auf nex via [xddxdd/nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel) mit `attic.xuyh0120.win/lantian` Binary Cache. CachyOS-abgeleitete sysctl/udev/PAM/bpftune-Tuning
- **ananicy-cpp** mit [CachyOS-Regeln](https://github.com/CachyOS/ananicy-rules) für automatische per-Prozess nice/ionice/sched Priorisierung
- **Cachix**: `noctalia.cachix.org` für fertige Noctalia-Binaries
- **PipeWire** Audio mit Low-Latency-Konfig

## Desktop / Compositor

Beide Hosts nutzen Noctalia als Shell (gestartet via `systemd --user`). Der Login-Manager ist der Noctalia Greeter; Umbriel registriert die Session selbst über seinen `.desktop`-Eintrag. Alle User-Services (Discord, Steam, udiskie, …) laufen als `systemd.user.services`.

### Noctalia IPC-Befehle

Für Tastenkürzel. Beispiele: `noctalia msg spotlight toggle`, `noctalia msg clipboard toggle`, `noctalia msg lockscreen lock`.

Die vollständige Liste steht in `memory.md`.

## Gaming (nur nex)

nex läuft im **NVIDIA-only Modus** (keine iGPU/PRIME Offloading) für maximale dGPU-Performance. Er hat einen dedizierten Gaming-Modul-Stack:

- Steam (mit Proton-GE, Hardware-Dekodierung)
- Lutris (custom Wrapper mit steam-run)
- Gamescope-Session
- Sunshine (Streaming)
- Lossless Scaling FG Vulkan Layer (aus `git.lsfg-vk.dev` gebaut, folgt dem `master`-Zweig und wird bei `nix flake update` automatisch mit aktualisiert; benötigt die DLL der Steam-Version über den Beta-Zweig)
- MangoHud
- DLSS Swapper / Zink-Wrapper

Plus eine dedizierte `/gaming`-Partition (ext4) auf einer separaten NVMe.

## Danksagungen

- [Noctalia](https://github.com/noctalia-dev/noctalia) – Desktop-Shell
- [Noctalia Greeter](https://github.com/noctalia-dev/noctalia-greeter) – Login-Manager
- [Umbriel](https://github.com/noctalia-dev/umbriel) – wlroots-basierter Wayland Compositor
- [bpftune](https://github.com/oracle/bpftune) – BPF-basierte Netzwerk-Auto-Optimierung (Oracle)
- [CachyOS](https://github.com/CachyOS) – Inspiration fürs Kernel-Tuning
- [CachyOS ananicy-rules](https://github.com/CachyOS/ananicy-rules) – Prozess-Priorisierungs-Regeln
- [xddxdd](https://github.com/xddxdd) – [nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel) mit fertigen CachyOS-Kernels und Binary Cache
- Der gesamten NixOS-Community für endlose Inspiration
