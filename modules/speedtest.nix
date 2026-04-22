{ config, pkgs, ... }:
let
  speedtestAuto = pkgs.writeShellScriptBin "speedtest-auto" ''
    # Die Option --selection-mode ist in älteren Versionen der CLI nicht verfügbar.
    # Ookla wählt standardmäßig automatisch den optimalen Server (meist nach Nähe/Ping).
    exec ${pkgs.ookla-speedtest}/bin/speedtest --accept-license --accept-gdpr "$@"
  '';
in
{
  environment.systemPackages = [
    pkgs.ookla-speedtest
    speedtestAuto
  ];
}
