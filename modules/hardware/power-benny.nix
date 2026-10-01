# Power-Profile-Steuerung fuer benny (Desktop)
# Aktiviert power-profiles-daemon (balanced/performance/power-saver).
# Noctalia + das game-performance-Script nutzen `powerprofilesctl`.
{ config, pkgs, ... }:

{
  services.power-profiles-daemon.enable = true;
}
