# Boot-Konfiguration fuer benny
# Intel CPU + AMD Radeon R9 280 (GCN 1.0 "Southern Islands", R9 200er-Serie).
#
# WICHTIG (GPU): Ab Kernel 6.19 defaultet der Kernel fuer GCN 1.0/1.1 auf den
# amdgpu-Treiber. Auf dieser Karte fuehrt das zu einem SCHWARZEN BILDSCHIRM
# (bekannter Bug: "amdgpu: probe with driver amdgpu failed with error -22",
# auch in 7.x noch nicht gefixt). Deshalb:
#   - 6.18-LTS verwenden (letzter Kernel VOR dem Default-Wechsel, offiziell
#     gepflegt bis Dez 2028), und
#   - amdgpu fuer SI/CIK explizit per Kernel-Param aktivieren. Genau dieser Weg
#     funktioniert(e) laut Bugreport bis inkl. 6.18 und liefert Vulkan/RADV.
#
# Sobald eine neuere Grafikkarte eingebaut ist: Kernel auf aktuell umstellen
# und die SI/CIK-Params hier entfernen.
{ config, pkgs, lib, ... }:

{
  imports = [ ./boot-common.nix ];

  # 6.18-LTS: letzter Kernel VOR dem amdgpu-SI-Default (6.19) -> Vulkan geht.
  # 6.18 ist LTS mit Sicherheits-Support bis Ende 2028.
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  boot.kernelParams = [
    # GCN 1.0 (Southern Islands, R9 270/280/280X) auf amdgpu statt radeon -> Vulkan/RADV
    "radeon.si_support=0"
    "amdgpu.si_support=1"
    # GCN 2.0 (Sea Islands, R9 290/390) ebenfalls auf amdgpu (falls die Karte doch GCN2 ist)
    "radeon.cik_support=0"
    "amdgpu.cik_support=1"

    # Intel CPU: aktiven P-State-Treiber verwenden
    "intel_pstate=active"

    # Wie lion/nex: THP-Verhalten
    "transparent_hugepage=madvise"
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
  };

  # Watchdog-Module abschalten (iTCO_wdt = Intel-Watchdog)
  boot.blacklistedKernelModules = [ "esp4" "esp6" "rxrpc" "algif_aead" "iTCO_wdt" ];

  # ZRAM 100% wie auf nex/lion (kein klassischer Swap)
  zramSwap.memoryPercent = lib.mkForce 100;
}
