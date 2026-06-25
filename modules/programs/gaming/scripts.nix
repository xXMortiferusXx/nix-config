{ config, pkgs, lib, ... }:

let
  game-performance = pkgs.writeShellScriptBin "game-performance" ''
    GAMODERUN="${pkgs.gamemode}/bin/gamemoderun"
    SMI="/run/current-system/sw/bin/nvidia-smi"
    PCTL="${pkgs.power-profiles-daemon}/bin/powerprofilesctl"
    BCTL="${pkgs.brightnessctl}/bin/brightnessctl"

    $PCTL set performance 2>/dev/null
    sudo $SMI -pm 1 2>/dev/null
    sudo $SMI -pl 130 2>/dev/null
    $BCTL set 100%
    echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null 2>&1

    echo "--- BEAST MODE: 130W TDP + Legion Performance ---"
    echo "--- GameMode uebernimmt CPU-Governor, I/O, Renice, GPU-Perf-Mode ---"

    systemd-inhibit --why "game-performance running" $GAMODERUN "$@"

    $PCTL set balanced 2>/dev/null
    sudo $SMI -pm 0 2>/dev/null
    $BCTL set 80%
    echo "balance_performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null 2>&1

    echo "--- Balanced Mode wiederhergestellt ---"
  '';

  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_SETTING=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json
    exec "$@"
  '';

in {
  environment.systemPackages = [
    game-performance
    nvidia-offload
  ];
}
