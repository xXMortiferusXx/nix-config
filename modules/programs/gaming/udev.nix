# Gemeinsame udev-Regeln für Gaming-Hosts (nex, lion-pc, benny).
# Controller für libinput unsichtbar machen (verhindert Zeiger/Cursor-Störung).
# WICHTIG: Spiele lesen Controller weiterhin über evdev → funktionieren trotz IGNORE.
{ config, pkgs, ... }:

{
  services.udev.extraRules = ''
    ENV{ID_INPUT_JOYSTICK}=="?*", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';
}