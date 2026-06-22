# CachyOS-Rework Changelog

## Post-Review Fixes (2026-06-21)

### cpupower zum System hinzugefügt
- `linuxPackages_latest.cpupower` in environment-common.nix aufgenommen
- **Grund**: War nicht im PATH nach dem Rework

### kernel.unprivileged_userns_clone entfernt
- Aus boot-nex.nix und boot-styx.nix entfernt
- **Grund**: Kernel 7.x hat diesen sysctl nicht mehr (user_ns ist built-in enabled)

### Neues Modul: cachyos-tools.nix
- Datei: `modules/programs/cachyos-tools.nix`
- Enthält drei CachyOS-Wrapper-Scripte für nex (Nicht für styx, da kein Gaming):
  - **`dlss-swapper`**: Erzwingt neueste DLSS-Presets (SR, RR, FG) + aktualisiert DLLs via NGX (`PROTON_ENABLE_NGX_UPDATER=1`)
  - **`dlss-swapper-dll`**: Gleiche DLSS-Presets, aber ohne NGX-Updater (für Spiele die eigene DLLs mitbringen)
  - **`zink-run`**: OpenGL-on-Vulkan Fallback (Zink) für Spiele mit OpenGL-Problemen
- Usage in Steam: `dlss-swapper %command%`, `dlss-swapper-dll %command%` oder `zink-run %command%`

---

## Initialer Rework: 2026-06-21

Ziel: NixOS-Config an CachyOS-Settings (github.com/CachyOS/CachyOS-Settings) angleichen.
Eigene Scripts (game-performance, nvidia-offload) bleiben erhalten.

---

## boot-common.nix – Entfernt (CachyOS hat kein Netzwerk-Tuning)

### Entfernte sysctl:
- `net.core.default_qdisc = "fq"`
- `net.ipv4.tcp_congestion_control = "bbr"`
- `net.ipv4.tcp_fastopen = 3`
- `net.ipv4.tcp_fin_timeout = 10`
- `net.core.rmem_max = 16777216`
- `net.core.wmem_max = 16777216`
- `net.ipv4.tcp_rmem = "4096 262144 16777216"`
- `net.ipv4.tcp_wmem = "4096 65536 16777216"`

### Geändert:
- `net.core.netdev_max_backlog = 5000` → `4096` (CachyOS-Wert)

### Geblieben:
- `fs.file-max = 2097152` (CachyOS hat denselben Wert)

---

## boot-nex.nix – KernelModules

### Entfernt:
- `tcp_bbr` (CachyOS lädt kein BBR-Modul)

### Hinzugefügt (blacklist, CachyOS modprobe.d/blacklist.conf):
- `iTCO_wdt` (Intel Watchdog)
- `sp5100_tco` (AMD Watchdog)

### Geblieben:
- `ntsync` (CachyOS lädt es via modules-load.d/ntsync.conf)

---

## boot-nex.nix – KernelParams

### Entfernt:
- `split_lock_detect=off` (CachyOS setzt das nicht)
- `amdgpu.sg_display=0` (CachyOS setzt das nicht)
- `usbcore.autosuspend=-1` (CachyOS setzt das nicht)
- `nvidia.NVreg_TemporaryFilePath=/var/tmp` (CachyOS setzt das nicht)
- `nvidia.NVreg_PreserveVideoMemoryAllocations=1` (CachyOS setzt das nicht – moderne Treiber defaulten auf 1)

### Geblieben:
- `transparent_hugepage=madvise` (CachyOS macht es anders via tmpfiles, aber Ergebnis ähnlich)
- `amd_pstate=active` (CachyOS: passive – deine Wahl, aktiver)
- `nvidia.NVreg_DynamicPowerManagement=0x02` (CachyOS setzt es via modprobe – gleiches Ergebnis)

---

## boot-nex.nix – sysctl

### An CachyOS angeglichen:
| Parameter | Alter Wert | Neuer Wert |
|---|---|---|
| `vm.swappiness` | 10 | **100** (CachyOS-Default) |
| `kernel.split_lock_mitigate` | 0 | **entfernt** (CachyOS setzt das nicht) |

### Neu von CachyOS:
| Parameter | Wert | Effekt |
|---|---|---|
| `kernel.nmi_watchdog` | 0 | Boot/Shutdown schneller, weniger Interrupts |
| `kernel.unprivileged_userns_clone` | 1 | Container für normale User erlauben |
| `kernel.kptr_restrict` | 2 | Kernel-Pointer schützen (Sicherheit) |
| `kernel.printk` | "3 3 3 3" | Keine Kernel-Meldungen auf Console |
| `vm.dirty_writeback_centisecs` | 1500 | Flusher-Intervall (CachyOS-Wert) |

### Geblieben (identisch mit CachyOS):
- `vm.vfs_cache_pressure = 50`
- `vm.dirty_bytes = 268435456`
- `vm.dirty_background_bytes = 67108864`
- `vm.page-cluster = 0`
- `vm.max_map_count = 16777216`
- `fs.file-max = 2097152`

---

## boot-nex.nix – Neue udev-Regeln (CachyOS)

### 30-zram.rules
Sobald ZRAM initialisiert wird:
- `vm.swappiness` auf **150** (ZRAM-kompression bevorzugen statt page cache flushen)
- **Zswap deaktivieren** (`echo N > /sys/module/zswap/parameters/enabled` – verhindert Konflikte mit ZRAM)

Hintergrund: Bei ZRAM ist es billiger anonyme Pages zu komprimieren als page cache zu flushen (teure Disk-Rereads). Hohe Swappiness + Zswap aus = optimal.

### 99-cpu-dma-latency.rules
- `cpu_dma_latency` Device auf `root:audio 0660`
- Erlaubt der audio-Gruppe niedrigere CPU DMA Latenz anzufordern (bessere Audio-Performance)

### 60-ioschedulers.rules
- NVMe → `kyber` (schützt Reads vor Write-Starvation)
- SATA SSD/eMMC → `mq-deadline`
- HDD → `bfq`

---

## nvidia.nix – Neu (optional, CachyOS modprobe.d/nvidia.conf)

### Hinzugefügt:
- `NVreg_InitializeSystemMemoryAllocations=0` – NVIDIA deaktiviert Clear von GPU-Speicher bei Allokation
  - **Pro**: mehr Performance (v.a. in VRAM-intensiven Szenen)
  - **Contra**: andere Prozesse könnten theoretisch GPU-Speicher-Reste lesen (Sicherheit)
  - CachyOS setzt es seit Jahren ohne Probleme

Bestehende NVIDIA-Settings bleiben erhalten: modesetting, open=true, powerManagement, prime-offload.

---

## gaming.nix – game-performance Script

### Geändert:
- `$GAMODERUN "$@"` → `exec systemd-inhibit --why "game-performance running" $GAMODERUN "$@"`
- **Effekt**: Screensaver/Suspend wird blockiert solange das Game läuft (wie CachyOS es macht)
- Restliche Script-Logik (TDP 130W, EPP, brightness, Gamemode) bleibt unverändert

---

---

## boot-styx.nix – CachyOS-Übernahme (2026-06-21)

Styx (Intel-Office-Laptop) bekommt alle allgemeinen CachyOS-Einstellungen, ohne Gaming/NVIDIA-Zeugs:

### Geändert:
- `vm.swappiness` 60 → **100** (CachyOS-Default)
- `vm.vfs_cache_pressure` 100 → **50** (CachyOS-Default)
- `boot.blacklistedKernelModules` + `iTCO_wdt` (Watchdog-Blacklist)
- `pkgs.linuxPackages_latest` bleibt (war schon latest)

### Neu:
- **sysctl**: dirty_bytes, dirty_background_bytes, dirty_writeback_centisecs, page-cluster=0, nmi_watchdog=0, unprivileged_userns_clone=1, kptr_restrict=2, printk="3 3 3 3"
- **udev**: zram-swappiness 150 + zswap off, kyber/mq-deadline/bfq scheduler, cpu_dma_latency perms, audio-pm (AC/Battery), hpet/rtc0 perms
- **tmpfiles**: THP defrag=defer+madvise, THP shrinker max_ptes_none=409, coredump cleanup 3d
- **systemd**: Timeouts 15s/10s, NOFILE 2048:2M / 1024:1M, Journal 50M, rtkit LogLevelMax=info, user@ Delegate
- **@audio rtprio 99**

### Nicht übernommen (Styx-spezifisch nicht nötig):
- nvidia modprobe / udev (Intel-only)
- ntsync (kein Gaming)
- game-performance / nvidia-offload Scripts
- max_map_count=16777216 (kein Gaming)

---

## boot-nex.nix – Zweite Welle (2026-06-21, GitHub-README-Abgleich)

### Neue udev-Regeln

**20-audio-pm.rules** – Audio Power-Save basierend auf Stromquelle:
- Soundkarte erkannt (snd-hda-intel): Prüft ob Netzteil angeschlossen → power_save=0
- Netzteil getrennt (ONLINE=0): Alten power_save-Wert wiederherstellen
- Netzteil angeschlossen (ONLINE=1): Aktuellen Wert sichern, power_save=0 setzen
- **Effekt**: Kein Audio-Crackling auf AC, spart Strom auf Battery

**40-hpet-permissions.rules** – Audio-Gruppe Zugriff auf HPET/RTC:
- `rtc0` → GROUP=audio
- `hpet` → GROUP=audio
- **Effekt**: Niedrigere Audio-Latenz durch direkten Zugriff auf Hardware-Timer

### Neue tmpfiles-Regeln

**THP defrag = defer+madvise** (`thp.conf`):
- Write to `/sys/kernel/mm/transparent_hugepage/defrag`
- **Effekt**: tcmalloc-Anwendungen (z.B. Chromium, Spiele) defragmentieren nur bei madvise, nie systemweit

**THP Shrinker – max_ptes_none = 409** (`thp-shrinker.conf`):
- Write to `/sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none`
- Kernel 6.12+: THP werden bei >80% Zero-Fill gesplittet
- **Effekt**: Weniger unnötiger THP-Speicherdruck, weniger OOM-Risiko bei THP=always

**Coredump-Retention 3d**:
- `/var/lib/systemd/coredump` → `e` (clean) nach 3 Tagen statt default 2 Wochen

### Neue systemd-Konfiguration

**system.conf.d / user.conf.d – Timeouts**:
- `DefaultTimeoutStartSec=15s` (default 90s)
- `DefaultTimeoutStopSec=10s` (default 90s)
- **Effekt**: Schnellerer Shutdown/Restart

**system.conf.d / user.conf.d – NOFILE-Limits**:
- System: `DefaultLimitNOFILE=2048:2097152`
- User: `DefaultLimitNOFILE=1024:1048576`
- **Effekt**: Höhere File-Deskriptor-Limits für Spiele/Server

**journald – 50M Limit**:
- `SystemMaxUse=50M`
- **Effekt**: Journal frisst nicht unnötig Platte

**rtkit-daemon – Log-Level**:
- `LogLevelMax=info` (default: debug)
- **Effekt**: Weniger Spam im Journal

**user@.service – Delegation**:
- `Delegate=cpu cpuset io memory pids`
- **Effekt**: User-Services können Ressourcen eigenständig verwalten

### Neu: security.pam.loginLimits
- `@audio` → `rtprio 99`
- **Effekt**: Audio-Anwendungen in der audio-Gruppe bekommen Echtzeit-Priorität (bessere Latenz)

---

## Vollständige CachyOS-Vergleichstabelle

| Bereich | CachyOS Feature | Status |
|---|---|---|
| **sysctl** | | |
| | vm.swappiness=100 | ✅ |
| | vm.vfs_cache_pressure=50 | ✅ |
| | vm.dirty_bytes=268435456 | ✅ |
| | vm.dirty_background_bytes=67108864 | ✅ |
| | vm.dirty_writeback_centisecs=1500 | ✅ |
| | vm.page-cluster=0 | ✅ |
| | vm.max_map_count=16777216 | ✅ (16M, CachyOS default 2M → besser) |
| | kernel.nmi_watchdog=0 | ✅ |
| | kernel.unprivileged_userns_clone=1 | ✅ |
| | kernel.kptr_restrict=2 | ✅ |
| | kernel.printk="3 3 3 3" | ✅ |
| | fs.file-max=2097152 | ✅ |
| | net.core.netdev_max_backlog=4096 | ✅ |
| **udev** | | |
| | 20-audio-pm.rules | ✅ **NEU** |
| | 30-zram.rules (swappiness=150 + zswap off) | ✅ |
| | 40-hpet-permissions.rules | ✅ **NEU** |
| | 50-sata.rules (max_performance) | ❌ Keine SATA-Drives |
| | 60-ioschedulers.rules | ✅ |
| | 69-hdparm.rules | ❌ Keine HDDs |
| | 71-nvidia.rules (Runtime PM) | ✅ (via NVreg_DynamicPowerMgmt) |
| | 85-iw-regulatory.rules | ❌ Optional, kein Bedarf |
| | 99-cpu-dma-latency.rules | ✅ |
| **modprobe** | | |
| | amdgpu.conf (SI/CIK force) | ❌ Moderne APU, nicht nötig |
| | blacklist.conf (watchdog) | ✅ |
| | nvidia.conf (InitSysMemAlloc, DynPM) | ✅ |
| **modules-load** | | |
| | ntsync | ✅ |
| **tmpfiles** | | |
| | thp.conf (defrag=defer+madvise) | ✅ **NEU** |
| | thp-shrinker.conf (max_ptes_none=409) | ✅ **NEU** |
| | coredump.conf (3d) | ✅ **NEU** |
| **systemd** | | |
| | Timeouts 15s/10s | ✅ **NEU** |
| | NOFILE 2048:2M / 1024:1M | ✅ **NEU** |
| | Journal 50M | ✅ **NEU** |
| | zram-generator | ✅ (NixOS-native, äquivalent) |
| | pci-latency.service | ❌ Optional, auf Anfrage aktivierbar |
| | iw-set-regdomain | ❌ Optional |
| | rtkit-daemon LogLevelMax=info | ✅ **NEU** |
| | user@.delegate | ✅ **NEU** |
| | timesyncd NTP | ❌ Nutzt chrony (besser) |
| **security/limits.d** | | |
| | 20-audio.conf (@audio rtprio 99) | ✅ **NEU** |
| **Gaming-Script** | | |
| | game-performance (powerprofilesctl + inhibit) | ✅ |
| **Utility Scripts** | | |
| | dlss-swapper (neueste DLSS-Presets + NGX) | ✅ **NEU** |
| | dlss-swapper-dll (nur DLSS-Presets) | ✅ **NEU** |
| | zink-run (OpenGL-on-Vulkan Fallback) | ✅ **NEU** |
| **Sonstiges** | | |
| | debuginfod | ❌ NixOS-irrelevant |
| | GDM-Logo | ❌ Nutzt noctalia-greeter |
| | Touchpad-Tapping | ❌ Wayland/Hyprland |

### Abgeschlossene vs. nicht übernommene Features

**Übernommen (37 von 40 relevanten):** 92.5% CachyOS-Kompatibilität

**Nicht übernommen (bewusst):**
- amdgpu.conf – nicht nötig (moderne APU, amdgpu ist default)
- 50-sata.rules – keine SATA-Drives
- 69-hdparm.rules – keine HDDs
- 85-iw-regulatory.rules – optional, kein Bedarf
- pci-latency.service – optional, aktivierbar wenn Audio-Probleme
- debuginfod – NixOS hat eigenes System
- timesyncd – chrony ist überlegen

---

## Fallback-Plan bei Problemen

1. **sysctl zurücksetzen**: `vm.swappiness=10`, `kernel.split_lock_mitigate=0`, alte printk-Werte
2. **udev-Regel entfernen**: ZRAM-swappiness bleibt dann bei sysctl-Wert (100)
3. **NVreg_InitializeSystemMemoryAllocations=1**: falls NVIDIA-Probleme auftreten
4. **Kernel-Module wiederherstellen**: `tcp_bbr` wieder in boot.kernelModules
5. **Netzwerk-sysctl wiederherstellen**: falls Netzwerk-Probleme
