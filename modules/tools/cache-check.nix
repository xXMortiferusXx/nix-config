{ config, pkgs, ... }:

let
  cache-check = pkgs.writeShellScriptBin "cache-check" ''
    echo "🔍 Prüfe Cache-Verfügbarkeit für das aktuelle System..."
    
    # Hole alle Build-Abhängigkeiten für die aktuelle Flake-Konfiguration
    # Wir filtern nach .drv Pfaden
    DRVS=$(nix path-info --derivation .#nixosConfigurations."Mortiferus-PC".config.system.build.toplevel)
    
    echo "📦 Analysiere Abhängigkeiten (das kann einen Moment dauern)..."
    
    # Nutze hydra-check oder eine einfache Abfrage, um zu sehen, was gebaut werden muss
    # --dry-run zeigt an, was heruntergeladen vs. gebaut wird
    OUT=$(nix-build --dry-run -E "with import <nixpkgs> {}; (builtins.getFlake (toString ./.)).nixosConfigurations.\"Mortiferus-PC\".config.system.build.toplevel" 2>&1)
    
    FETCH=$(echo "$OUT" | grep "will be fetched" | wc -l || echo "0")
    BUILD=$(echo "$OUT" | grep "will be built" | wc -l || echo "0")
    
    echo "---------------------------------------"
    echo "📥 Pakete aus dem Cache: $FETCH"
    echo "🔨 Pakete zum Kompilieren: $BUILD"
    echo "---------------------------------------"
    
    if [ "$BUILD" -gt 50 ]; then
      echo "⚠️ WARNUNG: Über $BUILD Pakete müssen lokal gebaut werden!"
      echo "Vielleicht sind die Cache-Server noch nicht synchronisiert."
      read -p "Trotzdem fortfahren? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          exit 1
      fi
    else
      echo "✅ Cache-Status sieht gut aus."
    fi
  '';

  nix-update-safe = pkgs.writeShellScriptBin "nix-update-safe" ''
    pushd /etc/nixos
    ${cache-check}/bin/cache-check
    if [ $? -eq 0 ]; then
      echo "🚀 Starte Update..."
      sudo nix flake update
      sudo nixos-rebuild switch --flake .#Mortiferus-PC
    else
      echo "❌ Update abgebrochen."
    fi
    popd
  '';
in
{
  environment.systemPackages = [
    cache-check
    nix-update-safe
  ];
}
