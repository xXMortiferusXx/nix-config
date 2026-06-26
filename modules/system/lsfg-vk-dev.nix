# Lossless Scaling Frame Generation Vulkan Layer
# Baut lsfg-vk aus Git (Input lsfg-vk-src) – ermöglicht Frame Gen auf Linux
{ config, pkgs, lib, inputs, ... }:

let
  lsfg-vk = pkgs.stdenv.mkDerivation rec {
    pname = "lsfg-vk";
    version = "2.0.0-dev";

    src = inputs.lsfg-vk-src;

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
      qt6.wrapQtAppsHook
    ];

    buildInputs = with pkgs; [
      vulkan-loader
      vulkan-tools
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qtshadertools
    ];

    cmakeFlags = [
      "-DLSFGVK_BUILD_VK_LAYER=ON"
      "-DLSFGVK_BUILD_UI=ON"
      "-DLSFGVK_BUILD_CLI=ON"
      "-DLSFGVK_INSTALL_XDG_FILES=ON"
      "-DLSFGVK_LAYER_LIBRARY_PATH=${placeholder "out"}/lib/liblsfg-vk-layer.so"
    ];

    preFixup = ''
      qtWrapperArgs+=(--prefix LD_LIBRARY_PATH : "${pkgs.vulkan-loader}/lib")
    '';

    meta = with lib; {
      description = "Lossless Scaling Frame Generation on Linux - Vulkan layer";
      homepage = "https://github.com/PancakeTAS/lsfg-vk";
      license = licenses.gpl3Plus;
      platforms = platforms.linux;
    };
  };
in
{
  environment.systemPackages = [ lsfg-vk ];
}
