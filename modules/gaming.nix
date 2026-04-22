{ config, pkgs, lib, ... }:

let
  game-performance = pkgs.writeShellScriptBin "game-performance" ''
    SMI="/run/current-system/sw/bin/nvidia-smi"
    LEGION="/run/current-system/sw/bin/legion_cli"
    PCTL="/run/current-system/sw/bin/powerprofilesctl"
    BCTL="${pkgs.brightnessctl}/bin/brightnessctl"

    # --- START-PHASE ---
    $PCTL set performance
    echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference

    $LEGION set-feature PlatformProfileFeature performance 2>/dev/null
    sudo $SMI -pm 1 2>/dev/null
    sudo $SMI -pl 130 2>/dev/null
    
    # Helligkeit auf 100% setzen
    $BCTL set 100%
    
    echo "--- BEAST MODE AKTIVIERT: 130W TDP ---"
    echo "--- Helligkeit auf 100% gesetzt ---"
    
    "$@"

    # --- END-PHASE (nach Beenden des Spiels) ---
    $PCTL set balanced
    echo "balance_performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
    
    $LEGION set-feature PlatformProfileFeature balanced 2>/dev/null
    sudo $SMI -pm 0 2>/dev/null
    
    # Helligkeit auf 80% zurückregeln
    $BCTL set 80%
    
    echo "--- Zurück im Balanced Mode ---"
    echo "--- Helligkeit auf 80% reduziert ---"
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
  environment.sessionVariables = {
    LD_LIBRARY_PATH = lib.mkForce [ 
      "/run/opengl-driver/lib" 
      "/run/opengl-driver-32/lib" 
    ];
    MANGOHUD_CONFIGFILE = "/home/mortiferus/.config/MangoHud/MangoHud.conf";
    PROTON_ENABLE_WAYLAND = "1";
  };

  programs.steam = {
    enable = true;
    protontricks.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = false;

    package = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [
        mangohud
      ];
    };

    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # Sunshine für Remote-Gaming (z.B. auf dem TV)
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
  };
  
  # Optimierung für Prioritäten
  security.pam.loginLimits = [
    { domain = "@wheel"; item = "nice"; type = "-"; value = "-20"; }
  ];

  users.users.mortiferus.packages = with pkgs; [
    lutris 
    heroic 
    bottles 
    gamescope
    # lsfg-vk    – nicht in nixpkgs verfügbar, Overlay wird noch benötigt
    # lsfg-vk-ui – nicht in nixpkgs verfügbar, Overlay wird noch benötigt
    umu-launcher
    # mangohud wird über home-manager verwaltet (siehe home.nix)
  ];

  environment.systemPackages = [ 
    game-performance
    nvidia-offload
  ];
}
