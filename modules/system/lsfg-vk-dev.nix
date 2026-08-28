# Lossless Scaling Frame Generation Vulkan Layer
# Baut lsfg-vk aus Git (Input lsfg-vk-src) – ermöglicht Frame Gen auf Linux
{ config, pkgs, lib, inputs, ... }:

let
  # WICHTIG: Clang als Compiler (wie die offizielle CI/Anleitung).
  # Mit GCC (stdenv-Default) bricht der Build an vulkan-hpp "ambiguous overload for operator=".
  # llvmPackages = Default-LLVM von nixpkgs (folgt automatisch, nicht extra gepinnt).
  stdenv = pkgs.llvmPackages.stdenv;

  lsfg-vk = stdenv.mkDerivation rec {
    pname = "lsfg-vk";
    version = "2.0.0-rc1";

    src = inputs.lsfg-vk-src;

    nativeBuildInputs = with pkgs; [
      cmake
      ninja
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
      "-G Ninja"
      "-DLSFGVK_BUILD_LAYER=ON"
      "-DLSFGVK_BUILD_UI=ON"
      "-DLSFGVK_BUILD_CLI=ON"
      "-DLSFGVK_MANAGED=ON"
      "-DLSFGVK_LAYER_LIBRARY_PATH=${placeholder "out"}/lib/liblsfg-vk-layer.so"
    ];

    preFixup = ''
      qtWrapperArgs+=(--prefix LD_LIBRARY_PATH : "${pkgs.vulkan-loader}/lib")
    '';

    meta = with lib; {
      description = "Lossless Scaling Frame Generation on Linux - Vulkan layer";
      homepage = "https://lsfg-vk.dev";
      license = licenses.cc-by-nc-nd-40;
      platforms = platforms.linux;
    };
  };
in
{
  environment.systemPackages = [ lsfg-vk ];
}
