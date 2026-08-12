{ config, pkgs, ... }:

{
  imports = [ ./environment-common.nix ];

  environment.variables = {
    # NVIDIA Shader-Disk-Cache (10 GB) — reduziert Stutter in Spielen
    "__GL_SHADER_DISK_CACHE_SIZE" = "12000000000";
    # Threaded OpenGL-Optimierungen
    "__GL_THREADED_OPTIMIZATIONS" = "1";
    # VSync deaktivieren (wird via Compositor/Game gesteuert)
    "__GL_SYNC_TO_VBLANK" = "0";
    # Explicit Sync für Wayland (NVIDIA 560+ — reduziert Tearing/Frame-Glitches)
    "__GL_EXPLICIT_SYNC_ENABLED" = "1";
    # Allow Flipping für bessere Wayland-Performance
    "__GL_ALLOW_FLIPPING" = "1";
  };
}
