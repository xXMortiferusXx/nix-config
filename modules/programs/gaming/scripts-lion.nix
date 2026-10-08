# Lion-spezifisches game-performance-Script.
# Helligkeit externer Monitore per DDC/CI: 100% bei Start, 80% via trap.
# Performance-Part (powerprofilesctl + EPP) greift erst mit P-State-CPU.
{ config, pkgs, lib, ... }:

let
  game-performance = pkgs.writeShellScriptBin "game-performance" ''
    PCTL="${pkgs.power-profiles-daemon}/bin/powerprofilesctl"
    DCTL="${pkgs.ddcutil}/bin/ddcutil"

    # GPU-Treiber-Libs (nvidia-ml, Mesa, ...) für LD_PRELOAD-Tools wie MANGOHUD
    export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    OLD_EPP=""
    for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
      [ -e "$f" ] || continue
      OLD_EPP="$OLD_EPP $f:$(<"$f")"
      echo performance | sudo tee "$f" >/dev/null 2>&1
    done
    $PCTL set performance >/dev/null 2>&1

    set_brightness_all() {
      # Setzt Helligkeit auf jedes Display, das per DDC/CI antwortet.
      local val="$1"
      local d
      for d in 1 2 3 4; do
        $DCTL setvcp 10 "$val" --display "$d" >/dev/null 2>&1
      done
    }

    restore() {
      $PCTL set balanced >/dev/null 2>&1
      set_brightness_all 80
      for entry in $OLD_EPP; do
        f="''${entry%:*}"; v="''${entry##*:}"
        echo "$v" | sudo tee "$f" >/dev/null 2>&1
      done
    }
    trap restore EXIT

    set_brightness_all 100

    echo "--- game-performance: Performance + Monitore auf 100%, Inhibit aktiv ---"
    systemd-inhibit --why "game-performance running" "$@"
    exit $?   # Exit-Code des Spiels; Zuruecksetzen ueber trap
  '';
in {
  environment.systemPackages = [
    game-performance
  ];
}
