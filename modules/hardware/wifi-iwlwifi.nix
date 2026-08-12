# iwlwifi TX-Aggregation Workaround fuer Intel WiFi-Chips
# Bei Ping-Spikes, niedrigem Durchsatz oder Verbindungsabbruechen unter Last
# kann fehlerhafte 802.11n-AC-Aggregation (AMSDU/AMPDU) die Ursache sein.
# 11n_disable=8 deaktiviert TX-Aggregation im iwlwifi-Treiber.
# 
# Hinweis: Das kann theoretisch den Maximal-Durchsatz reduzieren,
# verbessert aber die Latenz-Stabilität bei bugger Firmware.
# Nach Reboot testen (ping, iperf3); bei keiner Besserung wieder entfernen.
{ config, pkgs, lib, ... }:

{
  boot.extraModprobeConfig = ''
    options iwlwifi 11n_disable=8
  '';
}
