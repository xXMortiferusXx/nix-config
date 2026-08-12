{ config, pkgs, ... }:

{
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  services.udisks2.enable = true;
#  networking.search = [ "lan" ];
  
  # ────────────────── DNS CACHING ──────────────────
  # Router (192.168.50.1) macht bereits DNS-over-TLS
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
