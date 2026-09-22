{ config, pkgs, ... }:

{
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;   # Power Save aus → keine Latenz/Verluste am Verbindungsstart
  };
  # WLAN-Backend iwd statt wpa_supplicant (2026-09-22):
  # iwlwifi+wpa_supplicant verliert intermittierend die Assotiations-Sync →
  # "verbunden, aber keine Konnektivität" bis zum manuellen Reconnect.
  # iwd managt das Reassoziieren selbst und hält Suspend/Resume sauberer.
  # HINWEIS: networking.wireless.iwd.enable wird vom NM-Modul automatisch
  # gesetzt, sobald backend == "iwd".
  networking.networkmanager.wifi.backend = "iwd";
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

  # RFC 4821: MTU-Probing NUR für Verbindungen mit klassischem Blackhole-Verlust
  # (z.B. Ubisoft Connect unter Proton) — Interface-MTU bleibt 1500, nichts anderes
  # wird angefasst.
  #
  # Auskommentiert: Hat nichts am Ubisoft-Login geändert. Deaktiviert → Rückfall
  # zum Kernel-Default (0). Wieder aktivieren nur, wenn ein Blackhole-Verlust
  # nachweislich auftritt.
  #boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1;
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
