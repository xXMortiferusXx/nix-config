{ config, pkgs, ... }:

{
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
}
