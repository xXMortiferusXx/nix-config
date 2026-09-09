{ config, pkgs, ... }:

{
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;   # Power Save aus → keine Latenz/Verluste am Verbindungsstart
  };
  # DE statt DFS-UNSET → korrekte Sendeleistung/EIRP.
  # `networking.wireless.regulatoryDomain` existiert nicht mehr. udev-Regel setzt
  # DE bei jeder Interface-Initialisierung (auch nach Suspend/Reconnect), weil
  # wpa_supplicant (via NetworkManager) die Domain sonst nach dem AP-Country
  # überschreiben kann.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="ieee80211", RUN+="${pkgs.iw}/bin/iw reg set DE"
  '';
  networking.firewall.enable = true;
  services.udisks2.enable = true;
#  networking.search = [ "lan" ];
  
  # ────────────────── DNS CACHING ──────────────────
  # ASUS (192.168.50.1) macht DNS
  # Hier nur lokales Caching für schnellere Auflösung
 services.resolved = {
     enable = true;
     settings.Resolve = {
 #        Domains = [ "lan" "~." ];
 	DNS = [ "192.168.50.1" ];
         MulticastDNS = "resolve";  # nur auflösen, nicht selbst announcen
         LLMNR = "no";
         DNSSEC = "allow-downgrade";
         DNSOverTLS = "opportunistic";
         FallbackDNS = [ "192.168.50.1" ];
     };
 };

  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };
  
#  services.avahi = {
#    enable = false;
#    nssmdns4 = true;
#    nssmdns6 = true;  # auch IPv6
#    openFirewall = true;
#    publish = {
#        enable = true;
#        addresses = true;
#        workstation = true;
#        userServices = true;
#    };
#  };

}
