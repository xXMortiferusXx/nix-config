{ config, pkgs, lib, ... }:

let
  my-lutris = pkgs.symlinkJoin {
    name = "lutris";
    paths = [ pkgs.lutris-unwrapped ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/lutris

      makeWrapper ${pkgs.steam-run}/bin/steam-run $out/bin/lutris \
        --add-flags "${pkgs.lutris-unwrapped}/bin/lutris" \
        --prefix PATH : "${lib.makeBinPath [ pkgs.cabextract pkgs.unzip pkgs.gnutls pkgs.p11-kit pkgs.wget ]}" \
        --set XDG_DATA_DIRS "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:${pkgs.adwaita-icon-theme}/share:$out/share" \
        --set FONTCONFIG_FILE "/etc/fonts/fonts.conf" \
        --run "${pkgs.fontconfig}/bin/fc-cache -s" \
        --set XCURSOR_PATH "~/.icons:~/.local/share/icons:/run/current-system/sw/share/icons"

      rm $out/share/applications/net.lutris.Lutris.desktop
      cp ${pkgs.lutris-unwrapped}/share/applications/net.lutris.Lutris.desktop $out/share/applications/
      chmod +w $out/share/applications/net.lutris.Lutris.desktop
      substituteInPlace $out/share/applications/net.lutris.Lutris.desktop \
        --replace "Exec=lutris" "Exec=$out/bin/lutris"
    '';
  };

in {
  environment.systemPackages = [ my-lutris ];
}
