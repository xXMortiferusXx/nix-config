{ config, pkgs, lib, ... }:

let
  game-performance = pkgs.writeShellScriptBin "game-performance" ''
    SMI="/run/current-system/sw/bin/nvidia-smi"
    PCTL="${pkgs.power-profiles-daemon}/bin/powerprofilesctl"
    BCTL="${pkgs.brightnessctl}/bin/brightnessctl"

    $PCTL set performance 2>/dev/null
    sudo $SMI -pm 1 2>/dev/null
    sudo $SMI -pl 130 2>/dev/null
    $BCTL set 100%
    echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null 2>&1

    echo "--- BEAST MODE: 130W TDP + Legion Performance ---"

    systemd-inhibit --why "game-performance running" "$@"

    $PCTL set balanced 2>/dev/null
    sudo $SMI -pm 0 2>/dev/null
    $BCTL set 80%
    echo "balance_performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null 2>&1

    echo "--- Balanced Mode wiederhergestellt ---"
  '';

in {
  environment.systemPackages = [
    game-performance
  ];
}
