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
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    
    # Offizieller Weg für Proton-GE
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
  };

  programs.gamemode.enable = true;

  # Optimierung für Prioritäten
  security.pam.loginLimits = [
    { domain = "@wheel"; item = "nice"; type = "-"; value = "-20"; }
  ];

  # Deine User-Pakete - jetzt alles direkt aus 'pkgs'!
  users.users.mortiferus.packages = with pkgs; [
    lutris 
    heroic 
    bottles 
    mangohud 
    gamescope
    game-performance 
    nvidia-offload 
    mesa-demos
    
    # Die offiziellen Pakete laut deiner Suche:
    lsfg-vk     # Die Engine
    lsfg-vk-ui  # Die GUI
  ];

  environment.systemPackages = [ 
    pkgs.mangohud 
    pkgs.gamemode 
    game-performance 
    nvidia-offload 
    pkgs.mesa-demos
  ];
}
