# Gamescope (capSysNice für Compositor-Optimierungen).
{ config, pkgs, ... }:

{
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
}
