{ config, lib, pkgs, ... }:

let
  alc287-mic-gain-script = pkgs.writeShellScriptBin "alc287-mic-gain" ''
    set -eu
    ${pkgs.alsa-utils}/bin/amixer -c 1 sset 'Capture' 47
    ${pkgs.alsa-utils}/bin/amixer -c 1 sset 'Mic Boost' 1
    ${pkgs.alsa-utils}/bin/amixer -c 1 sset 'Internal Mic Boost' 0
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
  alc287-wp-conf = pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/94-alc287-mic.conf" ''
    wireplumber.settings = {
      device.restore-routes = false
      device.routes.default-sink-volume = 1.0
      device.routes.default-source-volume = 0.20
    }
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

  services.udev.extraRules = ''
    SUBSYSTEM=="sound", KERNEL=="controlC1", ACTION=="add", RUN+="${alc287-mic-gain-script}/bin/alc287-mic-gain"
  '';
}