# iwlwifi Bluetooth-Koexistenz-Deaktivierung fuer Intel WiFi-Chips
# Der AX210 ist ein WiFi+BT Combo-Chip. bt_coex_active=0 zwingt den Treiber,
# die Airtime nicht mit Bluetooth zu teilen. Das kann die WLAN-Stabilitaet
# unter Volllast verbessern, ohne Durchsatz-Einbussen zu verursachen.
# Hinweis: Bluetooth am AX210 ist dann komplett deaktiviert.
# Testen nach Reboot (ping, Download); bei keiner Besserung wieder entfernen.
{ config, pkgs, lib, ... }:

{
  boot.extraModprobeConfig = ''
    options iwlwifi bt_coex_active=0
  '';
}
