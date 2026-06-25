{ config, pkgs, inputs, ... }:

{
  environment.systemPackages = [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.swappy
    pkgs.slurp
  ];

  services.dbus.enable = true;
}
