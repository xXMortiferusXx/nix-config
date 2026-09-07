# Gemeinsame udev-Regeln für Gaming-Hosts (nex + lion-pc)
# Controller/Gamepads für libinput unsichtbar machen, damit sie nicht als
# Zeiger/Cursor stören (z.B. DualSense/DS4-Touchpad "…Controller Touchpad").
# WICHTIG: Spiele lesen Controller direkt über evdev (SDL/steaminput/…), nicht
# über libinput → Controller FUNKTIONIEREN trotz IGNORE weiterhin.
{ config, pkgs, ... }:

{
  services.udev.extraRules = ''
    ENV{ID_INPUT_JOYSTICK}=="?*", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';
}