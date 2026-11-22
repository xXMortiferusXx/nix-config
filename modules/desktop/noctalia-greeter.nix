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

    # Keine Uhr im Greeter (bewusst):
    # Die Uhrfarbe ist immer on_surface der Shell-Palette (Light-Mode -> #1B1B1B,
    # also schwarz) und der Greeter kann weder Farbe, Schatten noch einen eigenen
    # Hintergrund setzen. Auf einem Foto ist sie damit unlesbar.
    # Die einzige Gegenmassnahme waere ein starker Wallpaper-Tint - der zerstoert
    # aber genau das, was den Login ausmacht (schoenes Hintergrundbild).
    # Der Lockscreen (Noctalia Shell) kann die Uhr voll gestalten und bleibt dafuer da.
    # Wichtig: blur/tint auch NICHT setzen. Bei per-Monitor-Wallpapern aus dem Sync
    # (eDP-1/eDP-2) wuerden globale Werte ohnehin ignoriert; das Bild bleibt roh.
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
