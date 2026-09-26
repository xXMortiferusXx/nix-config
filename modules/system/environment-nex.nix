{ config, pkgs, ... }:

{
  imports = [ ./environment-common.nix ];

  environment.variables = {
    # NVIDIA Shader-Disk-Cache (12 GB) — reduziert Stutter in Spielen
    "__GL_SHADER_DISK_CACHE_SIZE" = "12000000000";

    # Lossless-Scaling-Vulkan-Layer abschalten (siehe lsfg-vk-dev.nix).
    # Grund: Der Layer wird vom Vulkan-Loader 1.4.357 abgewiesen, weil die
    # gebaute Bibliothek weder vkGetInstanceProcAddr noch das Legacy-Symbol
    # layer_vkGetInstanceProcAddr exportiert. Folge war bisher bei JEDEM
    # Vulkan-Prozess stderr-Rauschen:
    #   [ERROR] loader_create_instance_chain: Failed to find
    #   'vkGetInstanceProcAddr' in layer ".../liblsfg-vk-layer.so"
    # Der Abschalter stammt aus dem Manifest selbst (disable_environment) und
    # wirkt ohne Rebuild. Wenn upstream das Symbol nachliefert, diese Zeile
    # einfach loeschen — dann wird der Layer wieder geladen.
    "DISABLE_LSFGVK" = "1";
  };
}
