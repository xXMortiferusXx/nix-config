# Steam mit Protontricks, RemotePlay und Gaming-Paketen.
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
      # Kein extraEnv nötig: XCURSOR_* kommen aus Umbriel, XCURSOR_PATH ist FHS-Standard.
      extraProfile = "unset TZ";
    };
  };
}
