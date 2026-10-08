# SteelSeries Arctis Pro + GameDAC Gen1 (USB 1038:1282 Audio, 1038:1280 Control/HID)
# Format/48kHz fixiert + Suspend aus gegen Knackser; USB-Autosuspend abgeschaltet.
{ ... }:

{
  environment.etc."wireplumber/wireplumber.conf.d/51-gamedac-stable.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          {
            device.name = "~alsa_card.usb-SteelSeries_SteelSeries_GameDAC*"
          }
        ]
        actions = {
          update-props = {
            audio.format = "S32LE"
            audio.samplerate = 48000
            audio.channels = 2
            audio.position = [ FL FR ]
          }
        }
      }
      {
        matches = [
          {
            node.name = "~alsa_output.usb-SteelSeries_SteelSeries_GameDAC*"
          }
        ]
        actions = {
          update-props = {
            session.suspend-timeout-seconds = 0
          }
        }
      }
    ]
  '';

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="1038", ATTR{idProduct}=="1282", ATTR{power/control}="on"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1038", ATTR{idProduct}=="1280", ATTR{power/control}="on"
  '';
}
