{ config, pkgs, lib, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  # SDDM deaktivieren (noctalia-greeter nutzt greetd)
  services.displayManager.sddm.enable = lib.mkForce false;
  services.xserver.enable = lib.mkForce false;

  programs.noctalia-greeter = {
    enable = true;
    package = inputs.noctalia-greeter.packages.${system}.default;

    settings.cursor = {
      theme = "Bibata-Modern-Ice";
      size = 24;
      package = pkgs.bibata-cursors;
    };
  };

  # PAM für greetd (Gnome Keyring entsperren)
  security.pam.services.greetd.enableGnomeKeyring = true;
}
