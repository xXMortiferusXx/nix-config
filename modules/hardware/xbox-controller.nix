# Xbox-Controller über den xone-Treiber (USB-Dongle sowie USB/Bluetooth).
# xpad-noone ist nur der Xbox-360-Ersatz hinter xone, hier nicht nötig — und es
# wird nicht signiert (würde den Kernel-`.cer`-Merge brechen). Daher aus.
{
  hardware.uinput.enable = true;
  hardware.xone.enable = true;
  hardware.xpad-noone.enable = false;
}
