{ config, pkgs, lib, ... }:

let
  extraCompatPaths = lib.makeSearchPathOutput "steamcompattool" "" [
    pkgs.proton-ge-bin
  ];
in
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
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = extraCompatPaths;
      };
      extraProfile = "unset TZ";
    };

    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };
}
