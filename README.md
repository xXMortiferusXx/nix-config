# Mortiferus NixOS Configuration

This is my personal NixOS flake managing two machines with a shared module system.

## Hosts

| Host | Hardware | Role |
|------|----------|------|
| **nex** | AMD Ryzen + NVIDIA RTX, Lenovo Legion Laptop | Gaming / Desktop |
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
├── desktop/           # Compositors (niri, hyprland), greeter, polkit, fonts
├── hardware/          # GPU drivers, audio, laptop features, legion, touchpad
├── home/              # Home-Manager per user (mortiferus + backbone)
├── programs/          # Gaming stack, tools, shell, terminal, editor, zen-browser
├── services/          # Noctalia (desktop shell), printing
├── system/            # Boot, kernel, btrfs, tuning, networking, nix-settings
└── users/             # User definitions
home/                  # Raw dotfiles (linked via home-manager xdg.configFile)
memory.md              # Dev notes (current state, IPC commands, systemd services)
```

### Design Principle

One file = one topic. Large files get split into submodules (e.g., `programs/gaming/` contains `steam.nix`, `lutris.nix`, `gamescope.nix`, …).

## Key Technologies

- **NixOS** (unstable channel) with **flakes**
- **Home Manager** for per-user dotfiles and services
- **Disko** for declarative partitioning
- **Noctalia v5** as desktop shell (launcher, notifications, clipboard, …)
- **Niri** (scrollable-tiling Wayland compositor) on nex, **Hyprland** available on both
- **CachyOS** kernel via [xddxdd/nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel) (BORE on nex, latest on styx)
- **Cachix**: `noctalia.cachix.org` for pre-built Noctalia binaries
- **PipeWire** audio with low-latency config

## Desktop / Compositor

Both hosts use Noctalia as the shell (started via `systemd --user`). The login manager is the Noctalia Greeter (`--session niri`). All user services (Vesktop, Steam, udiskie, …) run as `systemd.user.services`.

### Noctalia IPC Commands

Used for keybind shortcuts. Example: `noctalia msg spotlight toggle`, `noctalia msg clipboard toggle`, `noctalia msg lockscreen lock`.

See `memory.md` for the full list.

## Gaming (nex only)

nex has a dedicated gaming module stack:

- Steam (with hardware decoding)
- Lutris (custom wrapper with steam-run)
- Gamescope session
- Feral Gamemode
- Sunshine (streaming)
- Lossless Scaling FG Vulkan layer (built from git)
- MangoHud
- DLSS Swapper / Zink wrappers

Plus a dedicated `/gaming` Btrfs partition.

## Acknowledgements

- [Noctalia](https://github.com/noctalia-dev/noctalia) – desktop shell
- [niri](https://github.com/YaLTeR/niri) – scrollable-tiling Wayland compositor
- [xddxdd](https://github.com/xddxdd) – CachyOS kernel package (nix-cachyos-kernel)
- [CachyOS](https://github.com/CachyOS) – kernel tuning inspiration
- All the NixOS community for endless inspiration

---

# 🇩🇪 Mortiferus NixOS Konfiguration

Meine persönliche NixOS-Flake, die zwei Rechner mit einem gemeinsamen Modulsystem verwaltet.

## Hosts

| Host | Hardware | Rolle |
|------|----------|-------|
| **nex** | AMD Ryzen + NVIDIA RTX, Lenovo Legion Laptop | Gaming / Desktop |
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
├── desktop/           # Compositor (niri, hyprland), Greeter, Polkit, Fonts
├── hardware/          # GPU-Treiber, Audio, Laptop-Features, Legion, Touchpad
├── home/              # Home-Manager pro User (mortiferus + backbone)
├── programs/          # Gaming-Stack, Tools, Shell, Terminal, Editor, Zen-Browser
├── services/          # Noctalia (Desktop-Shell), Drucken
├── system/            # Boot, Kernel, Btrfs, Tuning, Netzwerk, Nix-Settings
└── users/             # Benutzerdefinitionen
home/                  # Rohe Dotfiles (via home-manager xdg.configFile verlinkt)
memory.md              # Entwickler-Notizen (aktueller Stand, IPC, systemd)
```

### Design-Prinzip

Eine Datei = ein Thema. Große Dateien werden in Untermodule aufgeteilt (z.B. `programs/gaming/` enthält `steam.nix`, `lutris.nix`, `gamescope.nix`, …).

## Wichtige Technologien

- **NixOS** (unstable-Channel) mit **Flakes**
- **Home Manager** für User-Dotfiles und -Services
- **Disko** für deklarative Partitionierung
- **Noctalia v5** als Desktop-Shell (Launcher, Notifications, Clipboard, …)
- **Niri** (scrollable-tiling Wayland Compositor) auf nex, **Hyprland** auf beiden verfügbar
- **CachyOS**-Kernel via [xddxdd/nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel) (BORE auf nex, latest auf styx)
- **Cachix**: `noctalia.cachix.org` für fertige Noctalia-Binaries
- **PipeWire** Audio mit Low-Latency-Konfig

## Desktop / Compositor

Beide Hosts nutzen Noctalia als Shell (gestartet via `systemd --user`). Der Login-Manager ist der Noctalia Greeter (`--session niri`). Alle User-Services (Vesktop, Steam, udiskie, …) laufen als `systemd.user.services`.

### Noctalia IPC-Befehle

Für Tastenkürzel. Beispiele: `noctalia msg spotlight toggle`, `noctalia msg clipboard toggle`, `noctalia msg lockscreen lock`.

Die vollständige Liste steht in `memory.md`.

## Gaming (nur nex)

nex hat einen dedizierten Gaming-Modul-Stack:

- Steam (mit Hardware-Dekodierung)
- Lutris (custom Wrapper mit steam-run)
- Gamescope-Session
- Feral Gamemode
- Sunshine (Streaming)
- Lossless Scaling FG Vulkan Layer (aus Git gebaut)
- MangoHud
- DLSS Swapper / Zink-Wrapper

Plus eine dedizierte `/gaming` Btrfs-Partition.

## Danksagungen

- [Noctalia](https://github.com/noctalia-dev/noctalia) – Desktop-Shell
- [niri](https://github.com/YaLTeR/niri) – Scrollable-Tiling Wayland Compositor
- [xddxdd](https://github.com/xddxdd) – CachyOS-Kernel-Paket (nix-cachyos-kernel)
- [CachyOS](https://github.com/CachyOS) – Inspiration fürs Kernel-Tuning
- Der gesamten NixOS-Community für endlose Inspiration
