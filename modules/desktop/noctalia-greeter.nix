# Noctalia Login-Greeter (DE-Tastatur, merkt letzte Session via sync.toml)
# Workaround: tmpfiles kann .toml-Symlink nicht kopieren -> fix-noctalia-greeter-toml
# Passwordloser Sync über Modul-Option passwordlessSyncUsers (je Host gesetzt).
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

    # Uhr gross und ruhig; Datum ausgeschrieben statt %x (Locale ist de_DE).
    # Position/Schrift kommen aus dem Sync (noctalia), Groessen sind logical px.
    [clock]
    time_format = "%H:%M"
    time_font_size = 64
    date_format = "%A, %d. %B"
    date_font_size = 16

    # Hintergrund leicht weichzeichnen und in Richtung Palette-Surface aufhellen:
    # die duenne Datumszeile war auf dem unruhigen Wallpaper schlecht lesbar.
    [appearance.wallpaper]
    blur = 0.25
    tint = 0.35
  '';

  systemd.tmpfiles.settings."10-noctalia-greeter" = {
    "/var/lib/noctalia-greeter".d = {
      user = "greeter";
      group = "greeter";
      mode = "0750";
    };
  };

  # tmpfiles .C kopiert den Symlink (read-only Store) -> echte Datei via cp -L anlegen.
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
