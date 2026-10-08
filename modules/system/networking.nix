# Netzwerk: NetworkManager (iwd-Backend), lokales DNS-Caching und Firewall.
{ config, pkgs, lib, ... }:

{
  options.network.dnsServer = lib.mkOption {
    type = lib.types.str;
    default = "192.168.50.1";
    example = "192.168.178.1";
    description = ''
      DNS-Server (und Fallback) des lokalen Routers. Default ist der ASUS
      (192.168.50.1) fuer nex/lion-pc. benny laeuft hinter einer FritzBox mit
      Standard-Config und setzt hier 192.168.178.1.
    '';
  };

  config = {
    networking.networkmanager = {
      enable = true;
      wifi.powersave = false;   # Power Save aus -> keine Latenzverluste am Verbindungsstart
    };
    # iwd statt wpa_supplicant: stabileres Reassozieren, saubereres Suspend/Resume.
    networking.networkmanager.wifi.backend = "iwd";
    # Reg-Domain DE per udev setzen (AP-Country kann sie sonst überschreiben).
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="ieee80211", RUN+="${pkgs.iw}/bin/iw reg set DE"
    '';
    networking.firewall.enable = true;
    services.udisks2.enable = true;

    # Lokales DNS-Caching; DNS kommt vom Router.
    services.resolved = {
      enable = true;
      settings.Resolve = {
        DNS = [ config.network.dnsServer ];
        MulticastDNS = "resolve";  # nur auflösen, nicht announcen
        LLMNR = "no";
        DNSSEC = "allow-downgrade";
        DNSOverTLS = "opportunistic";
        FallbackDNS = [ config.network.dnsServer ];
      };
    };

    services.gvfs = {
      enable = true;
      package = pkgs.gvfs;
    };

  };
}
