{ config, pkgs, ... }:
let
  speedtestAuto = pkgs.writeShellScriptBin "speedtest-auto" ''
    exec ${pkgs.ookla-speedtest}/bin/speedtest --accept-license --selection-mode ping "$@"
  '';
in
{
  environment.systemPackages = [
    pkgs.ookla-speedtest
    speedtestAuto
  ];
}
