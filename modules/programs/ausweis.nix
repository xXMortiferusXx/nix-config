# AusweisApp: eID-Client des Bundes (Personalausweis auslesen, PIN verwalten,
# Online-Ausweisen z. B. Kfz-Abmeldung).
# Kein pcscd: der Ausweis wird per Smartphone-App als Kartenleser gelesen (NFC,
# gleiches WLAN). pcscd waere nur fuer einen USB-CCID-Leser noetig.
#
# "Smartphone als Kartenleser": Koppeln laeuft ueber Port 24727 (UDP-Broadcast
# zum Finden, TCP fuer die Verbindung). Ohne Freigabe findet das Handy den
# Rechner nicht ("Koppeln klappt nicht"). Bewusst nur auf den LAN-Interfaces,
# nicht global - in einem fremden WLAN ist die Funktion ohnehin unbrauchbar.
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.ausweisapp ];

  networking.firewall.interfaces = {
    wlan0.allowedTCPPorts = [ 24727 ];
    wlan0.allowedUDPPorts = [ 24727 ];
    eno1.allowedTCPPorts = [ 24727 ];
    eno1.allowedUDPPorts = [ 24727 ];
  };
}
