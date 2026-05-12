{ config, pkgs, ... }:

{
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # ────────────────── DNS CACHING ──────────────────
  # Router (192.168.50.1) macht bereits DNS-over-TLS
  # Hier nur lokales Caching für schnellere Auflösung
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "opportunistic";
      FallbackDNS = [
        "192.168.50.1"
      ];
    };
  };
}
