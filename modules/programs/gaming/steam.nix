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
      ];
      extraEnv = {
        XCURSOR_THEME = "Bibata-Modern-Ice";
        XCURSOR_SIZE = "24";
        XCURSOR_PATH = "/usr/share/icons:/usr/local/share/icons:$HOME/.icons:$HOME/.local/share/icons";
      };
      extraProfile = "unset TZ";
    };
  };
}
