{ config, pkgs, lib, inputs, ... }:

let
  lsfg-vk-dev = final: final.stdenv.mkDerivation {
      pname = "lsfg-vk";
      version = "2.0.0-dev";

      src = inputs.lsfg-vk-dev;

      nativeBuildInputs = [ final.cmake final.pkg-config final.qt6.wrapQtAppsHook ];

      buildInputs = [ final.vulkan-headers final.qt6.qtdeclarative ];

      cmakeFlags = [
        "-DLSFGVK_BUILD_VK_LAYER=ON"
        "-DLSFGVK_BUILD_CLI=ON"
        "-DLSFGVK_BUILD_UI=ON"
        "-DLSFGVK_INSTALL_XDG_FILES=ON"
      ];

      postPatch = ''
        substituteInPlace lsfg-vk-layer/VkLayer_LSFGVK_frame_generation.json.in \
          --replace-fail "@LSFGVK_LAYER_LIBRARY_PATH@" "$out/lib/liblsfg-vk-layer.so"
      '';

      meta = with lib; {
        description = "Vulkan layer for frame generation (Requires owning Lossless Scaling)";
        homepage = "https://github.com/PancakeTAS/lsfg-vk/";
        license = licenses.mit;
        platforms = platforms.linux;
      };
    };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      lsfg-vk = lsfg-vk-dev final;
      lsfg-vk-ui = final.lsfg-vk;
    })
  ];
}
