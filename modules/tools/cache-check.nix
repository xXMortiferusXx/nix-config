{ config, pkgs, ... }:

let
  cache-check = pkgs.writeShellScriptBin "cache-check" ''
    echo "🔍 Prüfe Cache-Verfügbarkeit für das aktuelle System..."
    
    # Wir nutzen nix build --dry-run, um zu sehen, was gebaut werden müsste.
    # Das funktioniert zuverlässig mit Flakes.
    echo "📦 Analysiere Abhängigkeiten (das kann einen Moment dauern)..."
    
    OUT=$(nix build .#nixosConfigurations."Mortiferus-PC".config.system.build.toplevel --dry-run 2>&1)
    
    # Extrahiere die Anzahl der Pakete aus der Ausgabe
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
      if [ "$BUILD" -eq 0 ] && [ "$FETCH" -eq 0 ]; then
          echo "✨ System ist bereits auf dem neuesten Stand (keine Änderungen)."
      else
          echo "✅ Cache-Status sieht gut aus."
      fi
    fi
  '';

  nix-update-safe = pkgs.writeShellScriptBin "nix-update-safe" ''
    pushd /etc/nixos > /dev/null
    
    echo "🔄 Aktualisiere Flake Inputs..."
    sudo nix flake update
    
    ${cache-check}/bin/cache-check
    if [ $? -eq 0 ]; then
      echo "🚀 Starte System-Rebuild..."
      sudo nixos-rebuild switch --flake .#Mortiferus-PC
    else
      echo "❌ Update abgebrochen. Rollback der flake.lock..."
      git checkout flake.lock 2>/dev/null || echo "Hinweis: Konnte flake.lock nicht automatisch zurücksetzen."
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
