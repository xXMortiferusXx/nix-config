{ config, pkgs, ... }: # "inputs" kann hier jetzt raus, wenn du es nicht für anderes brauchst

let
  # Deine Beast-Mode & Offload Skripte bleiben gleich
  game-performance = pkgs.writeShellScriptBin "game-performance" ''
    SMI="/run/current-system/sw/bin/nvidia-smi"
    LEGION="/run/current-system/sw/bin/legion_cli"
    PCTL="/run/current-system/sw/bin/powerprofilesctl"
    $PCTL set performance
    $LEGION set-feature PlatformProfileFeature performance 2>/dev/null
    sudo $SMI -pm 1 2>/dev/null
    sudo $SMI -pl 130 2>/dev/null
    echo "--- BEAST MODE AKTIVIERT: 130W TDP & Rote LED ---"
    "$@"
    $PCTL set balanced
    $LEGION set-feature PlatformProfileFeature balanced 2>/dev/null
    sudo $SMI -pm 0 2>/dev/null
    echo "--- Zurück im Balanced Mode ---"
  '';

  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_SETTING=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';
in
{
  
# 1. Die Variable global setzen (Steam zieht sich die beim Start)
  environment.sessionVariables = {
    MANGOHUD_CONFIG = "legacy_layout=0,table_columns=3,gpu_stats,gpu_temp,gpu_core_clock,gpu_mem_temp,vram,gpu_color=2E9762,cpu_stats,cpu_temp,cpu_mhz,cpu_color=2E97CB,ram,fps,fps_metrics=avg+0.01,frame_timing,background_alpha=0.4,font_size=20";  
  };

  # 2. Dein Steam Block bleibt sauber
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = false;

    package = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        mangohud
      ];
    };

    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
  };
# Sunshine um mal auf dem TV zocken zu können
  services.sunshine = {
  enable = true;
  autoStart = false; # Startet Sunshine direkt beim Booten
  capSysAdmin = true; # Erleichtert den Zugriff auf die GPU-Buffer
  };
  
  # Optimierung für Prioritäten
  security.pam.loginLimits = [
    { domain = "@wheel"; item = "nice"; type = "-"; value = "-20"; }
  ];

  # Deine User-Pakete - jetzt alles direkt aus 'pkgs'!
  users.users.mortiferus.packages = with pkgs; [
    lutris 
    heroic 
    bottles 
    gamescope
    mangohud

    # Die offiziellen Pakete laut deiner Suche:
    lsfg-vk     # Die Engine
    lsfg-vk-ui  # Die GUI
  ];

 # Das hier sorgt dafür, dass Mangohud & Gamemode perfekt ins System integriert werden
  programs.gamemode.enable = true;

  environment.systemPackages = [ 
    game-performance 
    #nvidia-offload 
  ];
}
