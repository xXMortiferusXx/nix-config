{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, vulkan-loader
, vulkan-tools
, qt6
, makeWrapper
}:

stdenv.mkDerivation rec {
  pname = "lsfg-vk";
  version = "2.0.0-dev";

  src = fetchFromGitHub {
    owner = "PancakeTAS";
    repo = "lsfg-vk";
    rev = "develop";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Muss berechnet werden
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    vulkan-loader
    vulkan-tools
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtquickcontrols2
    qt6.qtshadertools
  ];

  cmakeFlags = [
    "-DLSFGVK_BUILD_VK_LAYER=ON"
    "-DLSFGVK_BUILD_UI=ON"
    "-DLSFGVK_BUILD_CLI=ON"
    "-DLSFGVK_INSTALL_XDG_FILES=ON"
  ];

  postFixup = ''
    # Wrap lsfg-vk-ui with proper Qt environment
    wrapProgram $out/bin/lsfg-vk-ui \
      --prefix QT_PLUGIN_PATH : "${qt6.qtbase}/lib/qt-6/plugins" \
      --prefix QML2_IMPORT_PATH : "${qt6.qtdeclarative}/lib/qt-6/qml"
  '';

  meta = with lib; {
    description = "Lossless Scaling Frame Generation on Linux - Vulkan layer";
    homepage = "https://github.com/PancakeTAS/lsfg-vk";
    license = licenses.gpl3Plus;
    maintainers = [ ];
    platforms = platforms.linux;
    sourceProvenance = [ sourceTypes.fromSource ];
  };
}
