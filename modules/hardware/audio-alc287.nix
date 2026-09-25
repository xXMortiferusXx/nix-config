{ config, lib, pkgs, ... }:

let
  alc287-mic-gain-script = pkgs.writeShellScriptBin "alc287-mic-gain" ''
    set -eu
    ${pkgs.alsa-utils}/bin/amixer -c 1 sset 'Capture' 47
    ${pkgs.alsa-utils}/bin/amixer -c 1 sset 'Mic Boost' 1
    ${pkgs.alsa-utils}/bin/amixer -c 1 sset 'Internal Mic Boost' 0
  '';

  # Leiser Anker für den periodischen Watchdog (kein Journal-Spam).
  alc287-mic-gain-quiet = pkgs.writeShellScriptBin "alc287-mic-gain-quiet" ''
    ${pkgs.alsa-utils}/bin/amixer -q -c 1 sset 'Capture' 47 2>/dev/null
    ${pkgs.alsa-utils}/bin/amixer -q -c 1 sset 'Mic Boost' 1 2>/dev/null
    ${pkgs.alsa-utils}/bin/amixer -q -c 1 sset 'Internal Mic Boost' 0 2>/dev/null
  '';

  # WirePlumber speichert pro Route Volumen/Mute in
  # ~/.local/state/wireplumber/default-routes und spielt sie bei jedem
  # Route-/Node-Change wieder auf. Auf dem ALC287 bekommt das Capture-Control
  # so denselben Verstärkungszustand wie zuvor. Restore wird deshalb deaktiviert
  # und die Defaults fest vorgegeben; zugleich wird der Ausgang auf 100 % geklemmt,
  # denn WP global default (0.064) würde ihn sonst nach jedem Route-Apply auf
  # ~6 % fallen lassen.
  # Wegen der nichtlinearen Codec-Kennlinie wurde empirisch gemessen:
  # source-volume 0.20 == Capture 47 == +18 dB. Hinzu kommt der Mic-Boost
  # (analoge Vorstufe) aus dem udev-Anker unten.
  #
  # Zusätzlicher Schutzwall gegen die zweite WP-Falle: die per-Node-Volumes
  # in ~/.local/state/wireplumber/stream-properties. Beim analogen Replug
  # (Stecker ab/auf) erzeugt WP den Source/Output-Neu, und der aus dem
  # Treiber-Reset resultierende Capture-Wert wird danach gespeichert und
  # permanent restauriert. state.restore-props=false sorgt dafür, dass WP die
  # ALSA-Nodes des ALC287 nie mehr mit gespeicherten Volumes/Mutes überbügelt
  # (gleiche Mechanik wie ASMs 93-asm-no-stream-restore.conf für HeSuVi).
  alc287-wp-conf = pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/94-alc287-mic.conf" ''
    wireplumber.settings = {
      device.restore-routes = false
      device.routes.default-sink-volume = 1.0
      device.routes.default-source-volume = 0.20
    }

    stream.rules = [
      {
        matches = [
          { node.name = "~alsa_output.pci-0000_06_00.6.*" }
          { node.name = "~alsa_input.pci-0000_06_00.6.*" }
        ]
        actions = {
          update-props = { state.restore-props = "false" }
        }
      }
    ]
  '';
in
{
  services.pipewire.wireplumber.configPackages = [ alc287-wp-conf ];

  # Anchor: Capture/Gain des ALC287 hart auf 0 dB setzen (Boot + Karten-Re-Add).
  systemd.services.alc287-mic-gain = {
    description = "Set ALC287 (Realtek) capture gain to 0 dB";
    wantedBy = [ "sound.target" "multi-user.target" ];
    after = [ "sound.target" ];
    unitConfig.ConditionPathExists = "/sys/class/sound/controlC1";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${alc287-mic-gain-script}/bin/alc287-mic-gain";
    };
  };

  # udev: Anker bei (a) Karten-Add, (b) Karten-Change und (c) analogen
  # Jack-Events (Mic/Headphone-Switch). Beim Replug des Analogsteckers
  # feuert kein controlC1-add (Karte bleibt am Bus) — nur der Jack-Switch.
  # Deshalb hier zusätzlich auf SUBSYSTEM=="input" der HD-Audio-Jacks.
  services.udev.extraRules = ''
    SUBSYSTEM=="sound", KERNEL=="controlC1", ACTION=="add", RUN+="${alc287-mic-gain-script}/bin/alc287-mic-gain"
    SUBSYSTEM=="sound", KERNEL=="controlC1", ACTION=="change", RUN+="${alc287-mic-gain-script}/bin/alc287-mic-gain"
    SUBSYSTEM=="input", KERNEL=="input*", KERNELS=="0000:06:00.6", ATTR{name}=="HD-Audio Generic *", ACTION=="add|change", RUN+="${alc287-mic-gain-script}/bin/alc287-mic-gain"
  '';

  # Der ALSA-Node bekommt beim WP-Start (auch ohne ASM!) die vorherige
  # Capture-Volume zurück (empirisch: vol 0.58 == Capture 63, das entspricht
  # +30 dB — der Anker wurde bei Kaltstart-Reihenfolgen überschrieben).
  # weder state.restore-props=false noch das Löschen der State-Dateien
  # verhindert das zuverlässig. Lösung: WP schreibt bei JEDEM Start
  # ~/.local/state/wireplumber/default-nodes neu — ein systemd.path-Trigger
  # darauf setzt den Anker automatisch nach jedem WP-Start nach (deckt auch
  # Kaltboot-WP-Start ab). Zusätzlich klemmt ein regelmäßiger Timer.
  systemd.user.paths.alc287-mic-gain-on-wp-state = {
    description = "Re-apply ALC287 mic gain when WirePlumber rewrites its state";
    wantedBy = [ "default.target" ];
    pathConfig = {
      PathChanged = "%h/.local/state/wireplumber/default-nodes";
      Unit = "alc287-mic-gain-on-wp-state.service";
    };
  };
  systemd.user.services.alc287-mic-gain-on-wp-state = {
    description = "Re-apply ALC287 mic gain after WirePlumber restart";
    wantedBy = [ "default.target" ];
    unitConfig.ConditionPathExists = "/sys/class/sound/controlC1";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${alc287-mic-gain-script}/bin/alc287-mic-gain";
    };
  };

  # Sicherheitsnetz: Ein Jack-Replug erzeugt KEIN udev-Event (Karte bleibt am
  # Bus, input-Gerät existiert weiter — nur EV_SW + ALSA-kcontrol ändern sich).
  # Deshalb feuert weder controlC1-add/change noch die input-Jack-Regel beim
  # Ab-/Anstecken; zugleich setzt der ALC287-Codec die Capture-Volume selbst
  # auf max (63) zurück. Ein periodischer Timer klemmt den Wert deshalb
  # idempotent alle 10 s — deckt Replug, WP-Restart und Boot-Races ab.
  systemd.user.timers.alc287-mic-gain-watchdog = {
    description = "Periodic ALC287 mic gain watchdog";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5s";
      OnUnitActiveSec = "10s";
      AccuracySec = "1s";
    };
  };
  systemd.user.services.alc287-mic-gain-watchdog = {
    description = "Periodic ALC287 mic gain watchdog";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${alc287-mic-gain-quiet}/bin/alc287-mic-gain-quiet";
    };
  };
}