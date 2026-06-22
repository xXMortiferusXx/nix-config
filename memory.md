# NixOS Config Memory

## Host: nex (nicht styx!)
- Legion Laptop mit NVIDIA RTX 3070 + AMD GPU (PRIME Offload)
- NixOS unstable, stateVersion 26.05
- Kernel: smallPkgs.linuxPackages_latest (via nixpkgs-small)
- Scheduler: scx_bpfland (Performance-Modus)

## Hardware
- AMD CPU mit `amd_pstate=active`
- NVIDIA: Open-Source Treiber, PRIME Offload, fine-grained Power Management
- Audio: Atlas Air Headset via PipeWire (Low-Latency)
- Gaming-Platte: `/dev/disk/by-label/GamingDrive` (btrfs, komprimiert)

## Aktuelle Änderungen

### lsfg-vk (GitHub develop branch)
- **Stand**: 2026-06-17 eingefügt, 2026-06-17 gefixt
- **Pfad**: `/etc/nixos/modules/system/lsfg-vk-dev.nix`
- **Input**: `lsfg-vk-src` in flake.nix (github:PancakeTAS/lsfg-vk/develop, flake=false)
- **Fix**: `LSFGVK_LAYER_LIBRARY_PATH` wird direkt in cmakeFlags übergeben (statt postFixup)
- **Vulkan Layer**: Wird unter `/run/current-system/sw/share/vulkan/implicit_layer.d/` installiert
- **VK_LAYER_PATH**: NICHT setzen – wird von Steam pressure-vessel ignoriert/entfernt
- **Steam/Proton**: Layer wird über `XDG_DATA_DIRS` gefunden (enthält `/run/current-system/sw/share`)
- **Updates**: `nix flake lock --update-input lsfg-vk-src` dann rebuild

### PoE2 Deadlock (2026-06-17)
- **Problem**: "Deadlock detected" in PoE2 bei DX12/VKD3D
- **Lösung**: Auf nativen Vulkan Renderer umgestellt
- **Status**: Deadlock damit vermieden, lsfg-vk kann aber nicht mit nativem Vulkan genutzt werden (da lsfg-vk ein Vulkan Layer ist, der über DX12/VKD3D funktioniert)
- **NVIDIA Optimierungen**: `__GL_THREADED_OPTIMIZATIONS=1`, `__GL_SYNC_TO_VBLANK=0`

### Config-Bereinigung (2026-06-17)
- **legcord** entfernt (überbleibsel, vesktop reicht)
- **ZRAM**: 100% (CachyOS-Style), Swapfile komplett entfernt
- **vm.max_map_count**: 16M → 1048576 (1M, Standard für Gaming)
- **NVIDIA GL**: `__GL_THREADED_OPTIMIZATIONS=1` + `__GL_SYNC_TO_VBLANK=0` hinzugefügt
- **LD_LIBRARY_PATH**: Aus gaming.nix entfernt (möglicherweise PoE2 Deadlock-Auslöser)
- **Test-Tools**: `vulkan-tools` zu mortiferus.nix hinzugefügt (`mesa-demos` schon via `environment-common.nix`)

### CachyOS-Tools Modul (2026-06-21)
- Neues Modul: `modules/programs/cachyos-tools.nix`
- Drei Wrapper-Scripts von CachyOS übernommen:
  - **`dlss-swapper`**: Erzwingt neueste DLSS-Presets + NGX-Updater
  - **`dlss-swapper-dll`**: DLSS-Presets ohne NGX-Updater
  - **`zink-run`**: OpenGL-on-Vulkan (Zink) Fallback
- Importiert in nex/configuration.nix (nur nex, styx kein Gaming)

### Post-CachyOS-Fixes (2026-06-21)
- **cpupower** zu environment-common.nix hinzugefügt (war nicht im PATH)
- **kernel.unprivileged_userns_clone** aus boot-nex.nix + boot-styx.nix entfernt (Kernel 7.x hat den sysctl nicht mehr)

### Bekannte Eigenheiten
- llvmpipe wird zusätzlich angezeigt (normal, ist Mesa Software-Renderer)
- gaming.nix: lsfg-vk Einträge entfernt (kommt aus lsfg-vk-dev.nix)
- Nautilus + Thunar sind beide installiert (Nautilus hübscher, Thunar schneller)
- Gaming-Launcher: Steam, Heroic, Lutris (mit steam-run Wrapper), Faugus, cartridges

## TODO
- [ ] Hash für lsfg-vk muss bei jedem Update manuell in flake.lock aktualisiert werden (via `nix flake lock --update-input`)
- [ ] Prüfen ob `__GL_SYNC_TO_VBLANK=0` zu Tearings führt (dann auf 1 setzen)
- [ ] Testen ob PoE2 Deadlock ohne `LD_LIBRARY_PATH` verschwindet
- [ ] Prüfen ob `glxgears` ohne `LD_LIBRARY_PATH` funktioniert
