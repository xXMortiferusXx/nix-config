# CachyOS-Wrapper-Scripts für Gaming
# dlss-swapper: NVIDIA DLSS-Preset-Override + NGX-Updater
# dlss-swapper-dll: gleiches ohne NGX-Updater
# zink-run: OpenGL via Zink (OpenGL-on-Vulkan) ausführen
{ pkgs, ... }:

let
  dlss-swapper = pkgs.writeShellScriptBin "dlss-swapper" ''
    # Forces Nvidia DLSS to use the latest preset for SR, RR and framegen + updates the dlss dlls via ngx
    export PROTON_ENABLE_NGX_UPDATER=1
    export DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE=on
    export DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE=on
    export DXVK_NVAPI_DRS_NGX_DLSS_FG_OVERRIDE=on
    export DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE_RENDER_PRESET_SELECTION=render_preset_latest
    export DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION=render_preset_latest
    exec "$@"
  '';

  dlss-swapper-dll = pkgs.writeShellScriptBin "dlss-swapper-dll" ''
    # Forces Nvidia DLSS to use the latest preset for SR, RR and framegen + skips ngx updater
    export DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE=on
    export DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE=on
    export DXVK_NVAPI_DRS_NGX_DLSS_FG_OVERRIDE=on
    export DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE_RENDER_PRESET_SELECTION=render_preset_latest
    export DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION=render_preset_latest
    exec "$@"
  '';

  zink-run = pkgs.writeShellScriptBin "zink-run" ''
    # Run OpenGL applications using the Zink Gallium driver (OpenGL-on-Vulkan)
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export GALLIUM_DRIVER=zink
    export __GLX_VENDOR_LIBRARY_NAME=mesa
    export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
    exec "$@"
  '';
in

{
  environment.systemPackages = [
    dlss-swapper
    dlss-swapper-dll
    zink-run
  ];
}
