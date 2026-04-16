{ config, pkgs, lib, ... }: # lib hinzugefügt für mkForce [cite: 58]

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
  ''; # [cite: 58, 59]

  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_SETTING=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  ''; # [cite: 60]
in
{
  
# 1. Die Variable global setzen (Steam zieht sich die beim Start)
  environment.sessionVariables = {
    # Korrigiert: Als Liste definiert und mkForce genutzt, um Konflikte zu lösen [cite: 61]
    LD_LIBRARY_PATH = lib.mkForce [ 
      "/run/opengl-driver/lib" 
      "/run/opengl-driver-32/lib" 
    ];
    MANGOHUD_CONFIG = "legacy_layout=0,table_columns=3,gpu_stats,gpu_temp,gpu_core_clock,gpu_mem_temp,vram,gpu_color=2E9762,cpu_stats,cpu_temp,cpu_mhz,cpu_color=2E97CB,ram,fps,fps_metrics=avg+0.01,frame_timing,background_alpha=0.4,font_size=20"; # [cite: 62]
  };

  # 2. Dein Steam Block bleibt sauber
  programs.steam = {
    enable = true; # [cite: 62]
    remotePlay.openFirewall = true; # [cite: 63]
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = false;

    package = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        mangohud # [cite: 64]
      ];
    };

    extraCompatPackages = [
      pkgs.proton-ge-bin # [cite: 65]
    ];
  };

# Sunshine um mal auf dem TV zocken zu können
  services.sunshine = {
    enable = true; # [cite: 66]
    autoStart = false; # Startet Sunshine direkt beim Booten [cite: 67]
    capSysAdmin = true; # Erleichtert den Zugriff auf die GPU-Buffer [cite: 67]
  };
  
  # Optimierung für Prioritäten
  security.pam.loginLimits = [
    { domain = "@wheel"; item = "nice"; type = "-"; value = "-20"; } # [cite: 69]
  ];

  # Deine User-Pakete - jetzt alles direkt aus 'pkgs'!
  users.users.mortiferus.packages = with pkgs; [
    lutris 
    heroic 
    bottles 
    gamescope
    mangohud
    lsfg-vk     # Die Engine
    lsfg-vk-ui  # Die GUI
  ]; # [cite: 70, 71]

  # Das hier sorgt dafür, dass Mangohud & Gamemode perfekt ins System integriert werden
  programs.gamemode.enable = true; # [cite: 72]
  environment.systemPackages = [ 
    game-performance 
    #nvidia-offload 
  ]; # [cite: 73]
}
