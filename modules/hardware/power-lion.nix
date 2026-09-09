# Power-Profile-Steuerung für lion-pc (Desktop)
# Aktiviert power-profiles-daemon für die Profile balanced/performance/power-saver.
# Das gaming-Script `game-performance` und Noctalia nutzen `powerprofilesctl`,
# das ohne aktiven Daemon nicht funktioniert. Kein Akku hier, aber das
# performance-Profil setzt den CPU-Governor zugunsten von Spielen um.
{ config, pkgs, ... }:

{
  services.power-profiles-daemon.enable = true;
}
