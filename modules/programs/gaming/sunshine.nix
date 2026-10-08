# Sunshine Game-Streaming-Host (nex).
{ config, pkgs, ... }:

{
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
  };
}
