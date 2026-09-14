{ config, pkgs, lib, inputs, ... }:

let
  pkgsList = import ./packages.nix pkgs;
in {
  home-manager.backupFileExtension = "backup";

  home-manager.users.mortiferus = { config, ... }: {
    imports = [
      ./config.nix
      ./autostart.nix
      ./mpv.nix
    ];

    programs.mangohud = {
      enable = true;
      enableSessionWide = false;
      settings = { };
    };

    programs.home-manager.enable = true;
    programs.noctalia.enable = true;
    programs.noctalia.systemd.enable = true;

    home.packages = pkgsList;
    home.username = "mortiferus";
    home.homeDirectory = "/home/mortiferus";
    home.stateVersion = "26.05";

    # Wine/Proton: ALSA-Backend (winealsa) statt PulseAudio nutzen, damit Spiele
    # 5.1 anhand der KANALZAHL erkennen (6ch) — nicht anhand der semantischen
    # Channel-Map. GameDAC bleibt dadurch knackfrei auf rohem AUX0-5.
    # Stereo-Spiele laufen korrekt (FL/FR + Stille auf den restlichen Kanälen).
    home.sessionVariables = {
      WINEALSA_CHANNELS = "6";
      WINEDLLOVERRIDES = "winepulse.drv=d";
    };
  };
}
