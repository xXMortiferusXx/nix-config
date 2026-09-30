# Noctalia Login-Greeter (DE-Tastatur, merkt letzte Session via sync.toml)
# Workaround: tmpfiles kann .toml-Symlink nicht kopieren → fix-noctalia-greeter-toml
#
# Paket + Modul kommen komplett aus nixpkgs (kein Flake-Input mehr).
# Passwordloser Sync läuft über die nixpkgs-Modul-Option
# `services.displayManager.noctalia-greeter.passwordlessSyncUsers` (je Host gesetzt).
{ config, pkgs, lib, ... }:
{
  services.displayManager.noctalia-greeter = {
    enable = true;
  };

  environment.etc."noctalia-greeter.toml".text = ''
    [keyboard]
    layout = "de"

    [appearance]
    # Passwort-Maskierung: "default" (gefuellte Kreise) oder "random" (zufaellige Symbole/Glyphs)
    password_style = "random"
  '';

  systemd.tmpfiles.settings."10-noctalia-greeter" = {
    "/var/lib/noctalia-greeter".d = {
      user = "greeter";
      group = "greeter";
      mode = "0750";
    };
  };

  # tmpfiles .C kopiert den Symlink (→ read-only nix-store)
  # Stattdessen: echte Datei via cp -L anlegen → beschreibbar für greeter-sync
  systemd.services.fix-noctalia-greeter-toml = {
    description = "Create writable greeter.toml (resolve symlink)";
    after = [ "systemd-tmpfiles-setup.service" ];
    before = [ "greetd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      rm -f /var/lib/noctalia-greeter/greeter.toml
      cp -L /etc/noctalia-greeter.toml /var/lib/noctalia-greeter/greeter.toml
      chown greeter:greeter /var/lib/noctalia-greeter/greeter.toml
      chmod 0644 /var/lib/noctalia-greeter/greeter.toml
    '';
  };
}
