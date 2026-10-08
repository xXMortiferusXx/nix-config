{ config, pkgs, lib, ... }:
{
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
        pulseaudio
        libusb1
      ];
      # XCURSOR_THEME/SIZE setzen wir hier NICHT mehr: Umbriel setzt sie aus
      # seiner [input.cursor]-Config und veröffentlicht sie seit Rev 1200
      # (#384) in die systemd-User-Umgebung -> Steam (per XDG-Autostart) erbt
      # sie. XCURSOR_PATH setzt Umbriel nicht, der bleibt hier (FHS-Pfade).
      extraEnv = {
        XCURSOR_PATH = "/usr/share/icons:/usr/local/share/icons:$HOME/.icons:$HOME/.local/share/icons";
      };
      extraProfile = "unset TZ";
    };
  };
}
