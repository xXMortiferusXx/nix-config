# Noctalia Login-Greeter (–session niri, DE-Tastatur)
# Workaround: tmpfiles kann .toml-Symlink nicht kopieren → fix-noctalia-greeter-toml
{ config, pkgs, lib, inputs, ... }:
let
  greeterPkg = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  programs.noctalia-greeter = {
    enable = true;
    package = greeterPkg;
    greeter-args = "--session niri";
  };

  # Polkit-Policy überschreiben: aktive Benutzer dürfen den Greeter-Apply-Helper
  # ohne Passwort ausführen. Die mitgelieferte Policy verlangt sonst auth_admin.
  environment.etc."polkit-1/actions/org.noctalia.greeter.apply-appearance.policy".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE policyconfig PUBLIC
     "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
     "http://www.freedesktop.org/standards/PolicyKit/1.0/policyconfig.dtd">
    <policyconfig>
      <action id="org.noctalia.greeter.apply-appearance">
        <description>Apply Noctalia Shell appearance to the greeter</description>
        <message>Authentication is required to sync wallpaper and colors to the login greeter</message>
        <defaults>
          <allow_any>no</allow_any>
          <allow_inactive>no</allow_inactive>
          <allow_active>yes</allow_active>
        </defaults>
        <annotate key="org.freedesktop.policykit.exec.path">${greeterPkg}/bin/noctalia-greeter-apply-appearance</annotate>
        <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>
      </action>
    </policyconfig>
  '';

  environment.etc."noctalia-greeter.toml".text = ''
    [keyboard]
    layout = "de"
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
