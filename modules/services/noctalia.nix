{ config, pkgs, inputs, ... }:

{
  # Installiert das Paket direkt aus dem Flake-Input
  environment.systemPackages = [ 
    inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.swappy
    pkgs.slurp
  ];

  # Noctalia benötigt DBus für die Kommunikation
  services.dbus.enable = true;
}
