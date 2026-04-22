{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "sddm-ltmnight-theme";
  version = "1.2.4";
  
  src = pkgs.fetchFromGitHub {
    owner = "hyprltm";
    repo = "ltmnight-sddm-theme";
    rev = "v1.2.4";
    sha256 = "sha256-QyCTVclRDqUtYJJwe3Gphrh9BgxMpOl+svEQCaNR+Iw=";
  };

  nativeBuildInputs = with pkgs; [
    qt6.qttools
    qt6.wrapQtAppsHook
  ];

  dontWrapQtApps = true;
  
  installPhase = ''
    mkdir -p $out/share/sddm/themes/ltmnight
    cp -aR . $out/share/sddm/themes/ltmnight/
    
    # Erstelle Konfigurationsdatei für animierte Shader
    cat > $out/share/sddm/themes/ltmnight/Themes/hyprltm.conf.user << EOF
[General]
Background="ltmnight"
PartialBlur="true"
FormPosition="center"
HideVirtualKeyboard="false"
VirtualKeyboardAutoShow="false"
EOF
  '';
}
