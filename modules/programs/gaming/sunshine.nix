# Sunshine Game-Streaming-Host (nex).
{ config, pkgs, lib, ... }:

{
  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
  };

  # Das nixpkgs-Sunshine-Modul setzt noch die veralteten
  # services.avahi.publish.*-Optionen. Auf die neuen settings.publish.*
  # umstellen und die alten auf null zwingen -> keine Eval-Warnungen mehr.
  services.avahi.settings.publish = {
    disable-publishing = false;
    disable-user-service-publishing = false;
    publish-addresses = true;
  };
  services.avahi.publish.enable = lib.mkForce null;
  services.avahi.publish.userServices = lib.mkForce null;
}
