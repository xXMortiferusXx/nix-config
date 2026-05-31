# NixOS Flake – Memory

## Übersicht

Zwei Hosts: **nex** (Gaming-Laptop, Lenovo Legion) und **styx** (Office-Notebook, Intel).
Ein User pro Host: `mortiferus` (nex) und `backbone` (styx), jeweils mit home-manager.

---

## Flake-Struktur

```
/etc/nixos/
├── flake.nix              # Einstieg: 2 nixosConfigurations (nex, styx)
├── flake.lock
├── hosts/
│   ├── nex/
│   │   ├── configuration.nix    # Host-spezifische Imports
│   │   ├── hardware-configuration.nix
│   │   ├── disk-config.nix      # Disko: Btrfs-Subvolumes (/, /home, /nix)
│   │   └── disko-gaming.nix     # Leert subvolumes{} für /gaming (separate Platte)
│   └── styx/
│       ├── configuration.nix
│       └── hardware-configuration.nix
├── modules/
│   ├── system/
│   │   ├── common.nix           # Zentraler Importbaum (locale, networking, security, nix-settings, audio, printing, noctalia, shell, editor, terminal, tools, desktop, greetd, niri, hyprland)
│   │   ├── boot-common.nix      # systemd-boot, ZRAM (60%), fstrim, chrony, earlyoom, nix.gc
│   │   ├── boot-nex.nix         # +boot-common; Kernel latest, full preempt, AMD pstate, ZRAM 100%, kein Swap, scx_bpfland Scheduler
│   │   ├── boot-styx.nix        # +boot-common; Kernel latest, Intel pstate, konservativ
│   │   ├── environment-common.nix  # nix-ld, systemPackages, Zen Policies
│   │   ├── environment-nex.nix  # +common; NVIDIA Shader Cache
│   │   ├── environment-styx.nix # +common; EDITOR=nvim
│   │   ├── locale.nix           # de_DE.UTF-8, Europe/Berlin, de-latin1
│   │   ├── networking.nix       # NetworkManager, resolved, gvfs
│   │   ├── nix-settings.nix     # flakes, cachix (hyprland, nix-community, noctalia)
│   │   ├── security.nix         # sudo, udev backlight
│   │   └── disko-basic.nix      # styx: 1 NVMe, Btrfs + 16G Swapfile
│   ├── hardware/
│   │   ├── nvidia.nix           # NVIDIA Prime Offload + AMD iGPU
│   │   ├── intel.nix            # Intel iGPU Treiber
│   │   ├── legion.nix           # Lenovo Legion Modul, AMD ucode, Controller, irqbalance
│   │   ├── laptop-common.nix    # Bluetooth, power-profiles-daemon, upower, fwupd, smartd, libinput
│   │   ├── atlas-air.nix        # Turtle Beach Atlas Air Headset PipeWire-Rule
│   │   ├── audio.nix            # PipeWire low-latency (48000, quantum 64-2048)
│   │   └── touchpad.nix         # udev: Touchpad auto-disable bei externer Maus
│   ├── users/
│   │   ├── mortiferus.nix       # User + zen-browser, ideaMaker Desktop
│   │   └── backbone.nix         # User + zen-browser
│   ├── home/
│   │   ├── mortiferus.nix       # home-manager: sidekick-nativ, MangoHud, mpv, xdg.configFile
│   │   └── backbone.nix         # home-manager: lightweight
│   ├── programs/
│   │   ├── shell.nix            # fish (eza, zoxide, bat, fzf, starship, fastfetch)
│   │   ├── editor.nix           # neovim (defaultEditor)
│   │   ├── terminal.nix         # kitty mit Config
│   │   ├── tools.nix            # Custom Aliase (nix-switch, conf-sync, etc.), nsearch-Funktion
│   │   └── gaming.nix           # steam, sunshine, game-performance, nvidia-offload, my-lutris
│   ├── services/
│   │   ├── noctalia.nix         # noctalia-shell Flake-Input
│   │   └── printing.nix         # CUPS + SANE (Scanner)
│   └── desktop/
│       ├── desktop.nix          # polkit, dconf, gnome-keyring, tumbler, xwayland, fonts
│       ├── greetd.nix           # nwg-hello + labwc (AKTIV, Niri+Hyprland Sessions)
│       ├── sddm.nix             # SDDM + ltmnight-Theme (AUSKOMMENTIERT)
│       ├── sddm-themes/ltmnight.nix  # Custom SDDM Theme aus GitHub
│       ├── plasma.nix           # KDE Plasma 6 (AUSKOMMENTIERT)
│       ├── niri.nix             # niri Compositor + xdg-portal + xwayland-satellite
│       └── hyprland.nix         # Hyprland aus Flake-Input
├── home/
│   ├── mortiferus/
│   │   └── config/
│   │       ├── niri/            # config.kdl, noctalia.kdl, login.jpg
│   │       ├── hypr/            # hyprland.lua
│   │       ├── noctalia/        # colors.json, plugins/, settings.json
│   │       ├── nvim/            # init.lua
│   │       └── pipewire/        # chatmixer.conf, HRIRs
│   └── backbone/
│       └── config/
│           ├── niri/            # config.kdl, noctalia.kdl
│           ├── noctalia/        # colors.json, plugins/, settings.json
│           ├── nvim/            # init.lua
│           └── pipewire/        # chatmixer.conf, HRIRs
├── install.sh
├── live-edit
├── result -> /result
└── memory.md                   # Diese Datei
```

---

## Hosts im Detail

### nex (Gaming / Lenovo Legion)
| Aspekt | Details |
|---|---|
| CPU | AMD (Ryzen) mit `amd_pstate=active`, `preempt=full` |
| GPU | NVIDIA RTX + AMD iGPU (Prime Offload) |
| RAM | ZRAM 100%, kein physikalischer Swap |
| Storage | 1. NVMe: Btrfs (/, /home, /nix) – 2. Platte: `/gaming` via Label; monatlicher Scrub + Balance (auch auf /gaming) |
| Scheduler | `scx_bpfland` im performance-Modus (systemd-Workaround wegen kaputtem services.scx) |
| Sound | Turtle Beach Atlas Air Headset (PipeWire-Rule in atlas-air.nix) |
| Gaming | Steam, Heroic, Lutris (steam-run-wrapper), Sunshine, game-performance-Script |
| Kernel | `linuxPackages_latest`, Module: `tcp_bbr`, `ntsync`, `kvm-amd` |

### styx (Office / Intel-Notebook)
| Aspekt | Details |
|---|---|
| CPU | Intel (6405U) mit `intel_pstate=active` |
| GPU | Intel iGPU (i915) |
| RAM | ZRAM 60%, 16G Swapfile |
| Storage | 1 NVMe: Btrfs (/, /home, /nix, /swap) |
| Scheduler | Kein spezieller (CFS) |
| Sound | Standard PipeWire |
| Besonderheiten | `cudaSupport = false`, `systembus-notify`, `smartd`, `earlyoom` aktiviert |
| Kernel | `linuxPackages_latest` |

---

## Desktop / Display Manager

- **Aktiv:** greetd + labwc + nwg-hello (Login mit Session-Wahl: Niri oder Hyprland)
- **Alternativen (auskommentiert):** SDDM (+ ltmnight-Theme), KDE Plasma 6
- **Beide Compositor installiert:** Niri + Hyprland (aus Flake-Input)

---

## Wichtige Pfade

| Pfad | Zweck |
|---|---|
| `flake.nix` | Flake-Einstieg, definiert Inputs & Outputs |
| `hosts/<host>/configuration.nix` | Host-spezifische Modul-Imports |
| `modules/system/common.nix` | Zentraler Modul-Importbaum |
| `modules/system/boot-<host>.nix` | Boot/Kernel-Konfiguration je Host |
| `modules/system/environment-<host>.nix` | Env-Vars/Systempackages je Host |
| `modules/programs/tools.nix` | Alle nix-*, conf-* Aliase |
| `modules/programs/gaming.nix` | Gaming-Tools (nur für nex per Import) |
| `modules/hardware/` | Hardware-spezifische Module |
| `home/<user>/config/` | Dotfiles (per out-of-store symlink via xdg.configFile) |

---

## Nützliche Befehle (aus tools.nix Aliase)

| Alias | Befehl |
|---|---|
| `nix-switch` | `nixos-rebuild switch --flake /etc/nixos#<hostname>` |
| `nix-check` | `nix flake update && build + nvd diff` |
| `nix-update` | `flake update + switch` |
| `nix-sync` | `git pull + switch` |
| `night-update` | Bildschirm aus + update + switch (inhibited) |
| `nix-clean` | GC + optimise + switch |
| `conf-sync` | `git add . && commit + push` |
| `nsearch` | FZF-gestützte nixpkgs-Suche |
| `nv-prime` | `nvidia-offload` |
