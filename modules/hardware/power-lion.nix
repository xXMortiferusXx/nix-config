# Power-Profile-Steuerung für lion-pc (Desktop)
# Aktiviert power-profiles-daemon (balanced/performance/power-saver).
# game-performance-Script und Noctalia nutzen `powerprofilesctl`.
{ config, pkgs, ... }:

{
  services.power-profiles-daemon.enable = true;
}
