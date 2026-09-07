{ config, pkgs, lib, ... }:

let
  game-performance = pkgs.writeShellScriptBin "game-performance" ''
    PCTL="${pkgs.power-profiles-daemon}/bin/powerprofilesctl"
    BCTL="${pkgs.brightnessctl}/bin/brightnessctl"

    # GPU-Treiber-Libs (nvidia-ml, Mesa, ...) für LD_PRELOAD-Tools wie MANGOHUD
    export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    OLD_EPP=""
    for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
      [ -e "$f" ] || continue
      OLD_EPP="$OLD_EPP $f:$(<"$f")"
      echo performance | sudo tee "$f" >/dev/null 2>&1
    done
    $BCTL set 100% 2>/dev/null
    $PCTL set performance 2>/dev/null

    restore() {
      $PCTL set balanced 2>/dev/null
      $BCTL set 80% 2>/dev/null
      for entry in $OLD_EPP; do
        f="''${entry%:*}"; v="''${entry##*:}"
        echo "$v" | sudo tee "$f" >/dev/null 2>&1
      done
    }
    trap restore EXIT

    echo "--- BEAST MODE: Performance-Profile + Inhibit ---"
    systemd-inhibit --why "game-performance running" "$@"
    exit $?   # Exit-Code des Spiels; Restore läuft über trap
  '';

in {
  environment.systemPackages = [
    game-performance
  ];
}
