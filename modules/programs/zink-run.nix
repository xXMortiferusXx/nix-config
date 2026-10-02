# zink-run: OpenGL-Anwendungen über den Zink-Gallium-Treiber (OpenGL-on-Vulkan)
# ausführen. Sinnvoll auf Hosts mit Vulkan-fähiger GPU (z. B. AMD/Mesa).
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "zink-run" ''
      # Run OpenGL applications using the Zink Gallium driver (OpenGL-on-Vulkan)
      export MESA_LOADER_DRIVER_OVERRIDE=zink
      export GALLIUM_DRIVER=zink
      export __GLX_VENDOR_LIBRARY_NAME=mesa
      export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
      exec "$@"
    '')
  ];
}
