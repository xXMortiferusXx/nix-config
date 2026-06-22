{ config, pkgs, lib, ... }:

let
  game-performance = pkgs.writeShellScriptBin "game-performance" ''
    GAMODERUN="${pkgs.gamemode}/bin/gamemoderun"
    SMI="/run/current-system/sw/bin/nvidia-smi"
    PCTL="${pkgs.power-profiles-daemon}/bin/powerprofilesctl"
    BCTL="${pkgs.brightnessctl}/bin/brightnessctl"

    # --- START-PHASE: Hardware-Tuning (GameMode-unabhaengig) ---
    # Platform Profile auf Performance (LED rot) + NVIDIA TDP + Helligkeit + EPP
    $PCTL set performance 2>/dev/null
    sudo $SMI -pm 1 2>/dev/null
    sudo $SMI -pl 130 2>/dev/null
    $BCTL set 100%
    echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference > /dev/null 2>&1

    echo "--- BEAST MODE: 130W TDP + Legion Performance ---"
    echo "--- GameMode uebernimmt CPU-Governor, I/O, Renice, GPU-Perf-Mode ---"

    # GameMode optimiert CPU-Governor, I/O-Priority, Renice, GPU-Performance-Mode
    # systemd-inhibit blockiert Screensaver/Suspend (CachyOS-Style)
    systemd-inhibit --why "game-performance running" $GAMODERUN "$@"

    # --- END-PHASE: Hardware zuruecksetzen (LED zurueck auf weiss) ---
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

   # UNSER FIX: Der Lutris-Wrapper (Steam-Run-Hack)
   my-lutris = pkgs.symlinkJoin {
    name = "lutris";
    paths = [ pkgs.lutris-unwrapped ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/lutris

      # Erweiterter Pfad für Winetricks und Installer-Komponenten
      # cabextract/unzip: Für .cab und .zip Archive
      # gnutls/p11-kit: Für SSL/HTTPS (wichtig für Patch-Server)
      # wget: Falls Winetricks Dateien nachladen muss
      makeWrapper ${pkgs.steam-run}/bin/steam-run $out/bin/lutris \
        --add-flags "${pkgs.lutris-unwrapped}/bin/lutris" \
        --prefix PATH : "${lib.makeBinPath [ pkgs.cabextract pkgs.unzip pkgs.gnutls pkgs.p11-kit pkgs.wget ]}" \
        --set XDG_DATA_DIRS "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:${pkgs.adwaita-icon-theme}/share:$out/share" \
        --set FONTCONFIG_FILE "/etc/fonts/fonts.conf" \
	--run "${pkgs.fontconfig}/bin/fc-cache -s" \
        --set XCURSOR_PATH "~/.icons:~/.local/share/icons:/run/current-system/sw/share/icons"

      # Desktop-Datei fixen
      rm $out/share/applications/net.lutris.Lutris.desktop
      cp ${pkgs.lutris-unwrapped}/share/applications/net.lutris.Lutris.desktop $out/share/applications/
      chmod +w $out/share/applications/net.lutris.Lutris.desktop
      substituteInPlace $out/share/applications/net.lutris.Lutris.desktop \
        --replace "Exec=lutris" "Exec=$out/bin/lutris"
    '';
  };
in

{
  environment.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    XCURSOR_PATH = [
      "$HOME/.icons"
      "$HOME/.local/share/icons"
      "/run/current-system/sw/share/icons"
    ];
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
        bibata-cursors
      ];
      extraEnv = {
        XCURSOR_THEME = "Bibata-Modern-Ice";
        XCURSOR_SIZE = "24";
      };
      extraProfile = "unset TZ";
    };

    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        reaper_freq = 5;
        desiredgov = "performance";
        softrealtime = "off";
        renice = -10;
        ioprio = 0;
        inhibit_screensaver = 1;
        disable_splitlock = 1;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
      };
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if ((action.id == "com.feralinteractive.GameMode.governor-helper" ||
           action.id == "com.feralinteractive.GameMode.gpu-helper" ||
           action.id == "com.feralinteractive.GameMode.cpu-helper" ||
           action.id == "com.feralinteractive.GameMode.procsys-helper") &&
          subject.isInGroup("gamemode"))
      {
        return polkit.Result.YES;
      }
    });
  '';

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # Controller-Touchpads als libinput ignorieren (DualSense/DualShock/Xbox)
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="input", ATTRS{name}=="*DualSense*Touchpad*", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    ACTION=="add|change", SUBSYSTEM=="input", ATTRS{name}=="*Wireless Controller Touchpad*", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    ACTION=="add|change", SUBSYSTEM=="input", ATTRS{name}=="*Xbox*Controller*", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';

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
    faugus-launcher
    heroic
    gamescope
    # lsfg-vk wird über modules/system/lsfg-vk-dev.nix installiert (GitHub-Version)
    umu-launcher
    protonplus
  ];

  environment.systemPackages = [
    game-performance
    nvidia-offload
    my-lutris
    pkgs.bibata-cursors
  ];
}
