# Lutris mit steam-run-Wrapper für FHS-Umgebung und funktionierende Schriftarten
{ config, pkgs, lib, ... }:

let
  fontPackages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
  ];

  lutris-fontconfig = pkgs.runCommand "lutris-fontconfig" {} ''
    mkdir -p $out/etc/fonts
    cat > $out/etc/fonts/fonts.conf << EOF
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      ${lib.concatMapStringsSep "\n" (f: "<dir>${f}</dir>") fontPackages}
      <cachedir>/tmp/lutris-fontconfig-cache</cachedir>
    </fontconfig>
    EOF
  '';

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
        --set FONTCONFIG_FILE "${lutris-fontconfig}/etc/fonts/fonts.conf" \
        --run "mkdir -p /tmp/lutris-fontconfig-cache && ${pkgs.fontconfig}/bin/fc-cache -fs" \
        --run 'mkdir -p "$HOME/.local/share/Steam/compatibilitytools.d" && ln -sfn ${pkgs.proton-ge-bin.steamcompattool} "$HOME/.local/share/Steam/compatibilitytools.d/${pkgs.proton-ge-bin.version}"' \
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
