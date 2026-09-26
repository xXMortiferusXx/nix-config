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

    # NACHTRAG 2026-09-26: Der Vulkan-Loader (1.4.357) verwirft den Layer
    # weiterhin. Ursache ist NICHT der Layer-Typ im Manifest, sondern die
    # gebaute Bibliothek: sie exportiert nur
    # vkNegotiateLoaderLayerInterfaceVersion und weder vkGetInstanceProcAddr
    # noch das Legacy-Symbol layer_vkGetInstanceProcAddr. Der Loader kann den
    # Layer damit nicht anbinden und ueberspringt ihn bei jedem Vulkan-Prozess:
    #   [ERROR] loader_create_instance_chain: Failed to find
    #   'vkGetInstanceProcAddr' in layer ".../liblsfg-vk-layer.so"
    # Vergleich: nixpkgs' lsfg-vk **1.0.0** exportiert
    # layer_vkGetInstanceProcAddr und wird fehlerfrei geladen — ist aber zu alt.
    # => Upstream-Bug in 2.0.0-rc1. Ein frueherer Versuch, den Manifest-Typ von
    # GLOBAL auf INSTANCE zu korrigieren, brachte nichts und wurde entfernt.
    # Bis upstream nachzieht, ist der Layer per DISABLE_LSFGVK=1 abgeschaltet
    # (siehe environment-nex.nix) — die Fehlermeldungen sind damit weg.

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
