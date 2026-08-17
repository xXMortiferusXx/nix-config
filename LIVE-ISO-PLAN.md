# Live-ISO Planung (Workflow zum Zeigen)

Stand: 2026-08-17

## Ziel

Bootfaehiges Live-ISO, das den eigenen Niri-Workflow zeigt (Noctalia-Greeter →
Niri → Fish/Nvim/Noctalia), ohne Gaming, ohne Secrets, auf beliebiger Hardware
(Intel/AMD/NVIDIA) benutzbar.

## Bereits entschieden

- [x] User: `live`, Passwort: `live`
- [x] Hostname: `live`
- [x] SFW-Wallpaper: `pexels-86419958-8956353.jpg` (ins Repo gebackt)
- [x] Greeter-Aussehen vorab einfrieren (Palette + Wallpaper statt Standard)
- [x] Noctalia: Automation aus, Wallpaper fixiert (keine Neu-Generierung)
- [x] Grafik: Mesa (Intel/AMD) + propriet. NVIDIA, ohne NVIDIA-Session-Vars

## Blocker: Black-Screen nach Login

Greeter lief, aber nach Login als `live` kam kein Niri. Zu pruefen:

- [ ] Session-Registrierung: greetd/Noctalia-Greeter muss wissen, wie es Niri
      startet (Wayland-Session `.desktop` + Session-Command). Vermutlich fehlt
      die Session-Verknuepfung fuer den `live`-User.
- [ ] Niri-Crash beim Start: fehlender GPU-Driver im QEMU (virtio-gpu) oder
      nex-spezifische Referenzen in der Niri-Config (Monitore, Outputs,
      Keybinds auf nicht installierte Apps).
- [ ] systemd-user-Session / xdg-portal startet nicht sauber.

### Schneller testen (ohne ISO-Neubau)

Direkt als VM booten statt ISO bauen:

```bash
nix build .#nixosConfigurations.live.config.system.build.vm --no-link
```

## App-Auswahl (Groesse reduzieren)

Die 5,4 GB kamen fast komplett von den schweren Apps.

### Essenziell (Workflow zeigen)

- [ ] Niri (+ Hyprland optional)
- [ ] Noctalia + Greeter
- [ ] Fish + Starship + Zoxide
- [ ] Nvim, Terminal
- [ ] Thunar (Dateimanager)
- [ ] Browser (Zen oder anderer)
- [ ] Wayland-Tools: grim, slurp, wl-clipboard, cliphist

### Weglassen / optional (schwer, nicht Workflow-relevant)

- [ ] LibreOffice, GIMP, Thunderbird
- [ ] Prusa Slicer, Orca Slicer (3D-Druck)
- [ ] Discord, cartridges, polychromatic, goverlay
- [ ] Steam/Gaming-Zeug

## Offene Fragen

- [ ] Live-User: echte Niri-Config (alle Keybinds) oder bereinigte Demo-Config
      ohne nex-spezifische Referenzen?
- [ ] Nur Niri oder auch Hyprland?
- [ ] Installer (`install.sh`) im ISO noetig oder nur "mal reinschauen"?

## Umsetzung (beim naechsten Versuch)

- [ ] Eigenes abgespecktes `packages.nix` nur fuer Live (statt mortiferus' Liste)
- [ ] Session-Registrierung fuer den `live`-User pruefen/fixen
- [ ] Niri-Config auf nex-spezifische Referenzen pruefen
- [ ] Erst VM-Test (schnell), dann ISO-Bau
