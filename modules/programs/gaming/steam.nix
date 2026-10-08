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
      # Kein extraEnv mehr nötig:
      # - XCURSOR_THEME/SIZE setzt Umbriel aus [input.cursor] und veröffentlicht
      #   sie seit Rev 1200 (#384) in die systemd-User-Umgebung -> Steam erbt sie.
      # - XCURSOR_PATH braucht es nicht: bibata-cursors liegt (via extraPkgs) im
      #   FHS unter /usr/share/icons, und das ist Standard-Xcursor-Pfad.
      extraProfile = "unset TZ";
    };
  };
}
