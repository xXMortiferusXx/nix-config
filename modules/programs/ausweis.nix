# AusweisApp: eID-Client des Bundes (Personalausweis auslesen, PIN verwalten,
# Online-Ausweisen z. B. Kfz-Abmeldung).
# Kein pcscd: der Ausweis wird per Smartphone-App als Kartenleser gelesen (NFC,
# gleiches WLAN). pcscd waere nur fuer einen USB-CCID-Leser noetig.
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.ausweisapp ];
}
