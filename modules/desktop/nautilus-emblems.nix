# Nautilus-Emblem für schreibgeschützte/systemverwaltete Dateien
# Kopiert Adwaita-Symbole als emblem-unwritable (emblem-important → nix-store)
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (pkgs.stdenvNoCC.mkDerivation {
      name = "nautilus-emblem-unwritable";
      buildInputs = [ pkgs.adwaita-icon-theme ];
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out/share/icons/hicolor/symbolic/emblems
        mkdir -p $out/share/icons/hicolor/16x16/emblems
        cp "${pkgs.adwaita-icon-theme}/share/icons/Adwaita/symbolic/legacy/emblem-important-symbolic.svg" \
          $out/share/icons/hicolor/symbolic/emblems/emblem-unwritable-symbolic.svg
        cp "${pkgs.adwaita-icon-theme}/share/icons/Adwaita/16x16/emblems/emblem-readonly.png" \
          $out/share/icons/hicolor/16x16/emblems/emblem-unwritable.png
      '';
    })
  ];
}
