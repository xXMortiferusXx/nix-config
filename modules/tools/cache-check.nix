{ config, pkgs, ... }:

let
  cache-check = pkgs.writeShellScriptBin "cache-check" ''
    echo "🔍 Prüfe Cache-Verfügbarkeit für das aktuelle System..."
    
    # Wir nutzen nix build --dry-run, um zu sehen, was gebaut werden müsste.
    echo "📦 Analysiere Abhängigkeiten (das kann einen Moment dauern)..."
    
    OUT=$(nix build .#nixosConfigurations."Mortiferus-PC".config.system.build.toplevel --dry-run 2>&1)
    
    # Extrahiere die Anzahl der Pakete aus der Ausgabe
    FETCH=$(echo "$OUT" | grep "will be fetched" | wc -l || echo "0")
    BUILD=$(echo "$OUT" | grep "will be built" | wc -l || echo "0")
    
    # Liste der Pakete, die gebaut werden würden (für die Analyse)
    BUILD_LIST=$(echo "$OUT" | grep -A 100 "will be built" | grep "/nix/store/" || true)
    
    echo "---------------------------------------"
    echo "📥 Pakete aus dem Cache: $FETCH"
    echo "🔨 Pakete zum Kompilieren: $BUILD"
    echo "---------------------------------------"
    
    # Wenn mehr als 5 Pakete gebaut werden sollen, prüfen wir genauer.
    # Ein paar kleine Ableitungen (wie die System-Konfiguration selbst) werden immer gebaut.
    if [ "$BUILD" -gt 10 ]; then
      echo "⚠️ KRITISCHE WARNUNG: $BUILD Pakete fehlen im Cache!"
      echo "Folgende Pakete müssten lokal kompiliert werden:"
      echo "$BUILD_LIST" | head -n 20
      echo "..."
      echo "---------------------------------------"
      echo "❌ ABBRUCH: Da du keine langen Kompilierzeiten möchtest,"
      echo "wurde der Vorgang gestoppt. Bitte versuche es später erneut,"
      echo "wenn die Cache-Server (Hydra/Cachix) fertig sind."
      exit 1
    fi

    if [ "$BUILD" -eq 0 ] && [ "$FETCH" -eq 0 ]; then
        echo "✨ System ist bereits auf dem neuesten Stand."
    else
        echo "✅ Cache-Status ist akzeptabel ($BUILD Builds)."
    fi
  '';

  nix-update-safe = pkgs.writeShellScriptBin "nix-update-safe" ''
    pushd /etc/nixos > /dev/null
    
    # Wir sichern die aktuelle flake.lock
    cp flake.lock flake.lock.bak

    echo "🔄 Aktualisiere Flake Inputs..."
    sudo nix flake update
    
    # Jetzt prüfen wir den Cache mit den NEUEN Inputs
    if ${cache-check}/bin/cache-check; then
      echo "🚀 Starte System-Rebuild..."
      if sudo nixos-rebuild switch --flake .#Mortiferus-PC; then
        echo "✅ Update erfolgreich abgeschlossen."
        rm flake.lock.bak
      else
        echo "❌ Rebuild fehlgeschlagen! Stelle alte flake.lock wieder her..."
        sudo mv flake.lock.bak flake.lock
        exit 1
      fi
    else
      echo "↩️ Cache unvollständig. Setze flake.lock zurück..."
      sudo mv flake.lock.bak flake.lock
      exit 1
    fi
    
    popd > /dev/null
  '';
in
{
  environment.systemPackages = [
    cache-check
    nix-update-safe
  ];
}
