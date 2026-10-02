# SteelSeries Arctis Pro + GameDAC Gen1 (USB 1038:1282 Audio + 1038:1280 Control/HID)
#
# Wiederhergestellt aus der nex-Historie (Commit 9235fa9) — wird fuer benny
# gebraucht, der das GameDAC jetzt nutzt. Zwei Bausteine gegen die bekannten
# Aussetzer/Knackser:
#
# 1) WirePlumber-Regel "51-gamedac-stable.conf":
#    - ALSA-Card auf S32LE/48kHz/2ch (FL/FR) festnageln -> hw_params bleiben
#      konstant, keine erneute Format-Negotiation bei Signalwechsel.
#    - Output-Node mit session.suspend-timeout-seconds = 0 -> der Sink schlaeft
#      nie ein (PipeWire-Standard: suspend nach ~5s Stille) -> kein Aufwach-
#      "Knacken"/Aussetzer nach Stillphasen.
#
# 2) USB-Autosuspend fuer das GameDAC abschalten (power/control=on).
#    Analog zum GC7-Fix (Commit 90c5ce4): der Autosuspend kann das Geraet in
#    einen inkonsistenten Zustand versetzen -> sporadischer, kompletter Ton-
#    ausfall bis zum Replug. Gilt fuer Audio- und Control-Interface.
#    (Die ASM-Filterketten selbst werden per Package-Patch warmgehalten, siehe
#     scripts/asm-pause-on-idle.py + Package-Override in der Host-Config.)
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
