# CachyOS-Wrapper-Scripts für Gaming (NVIDIA).
# dlss-swapper: DLSS-Preset-Override + NGX-Updater.
# dlss-swapper-dll: wie oben, ohne NGX-Updater (zink-run liegt in zink-run.nix).
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
in

{
  environment.systemPackages = [
    dlss-swapper
    dlss-swapper-dll
  ];
}
