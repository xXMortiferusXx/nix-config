# Polkit-Regeln
# - noctalia-greeter: apply-appearance passwordlos für wheel-Mitglieder
#   (Fallback für inactive Sessions, z.B. während Lockscreen)
# - NetworkManager: wheel-Gruppe darf Netzwerk verwalten ohne Passwort
# - Flatpak/Bazaar: wheel kann Flatpak-Apps installieren ohne Passwort
#   (konsistent zu wheelNeedsPassword = false; lion-pc nutzt das für Bazaar,
#    auf nex/styx ohne Flatpak-Dienst wirkungslos)
{ config, pkgs, lib, ... }:

{
  security.polkit.enable = true;
  # NixOS unstable: pkexec-Wrapper wird nicht mehr automatisch erstellt
  security.polkit.enablePkexecWrapper = true;

  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.noctalia.greeter.apply-appearance" &&
          subject.isInGroup("wheel"))
      {
        return polkit.Result.YES;
      }
    });

    polkit.addRule(function (action, subject) {
      var network_actions = [
        "org.freedesktop.NetworkManager.enable-disable-network",
        "org.freedesktop.NetworkManager.enable-disable-wifi",
        "org.freedesktop.NetworkManager.enable-disable-wwan",
        "org.freedesktop.NetworkManager.network-control",
        "org.freedesktop.NetworkManager.settings.modify.own",
        "org.freedesktop.NetworkManager.settings.modify.system",
        "org.freedesktop.NetworkManager.wifi.scan",
        "org.freedesktop.NetworkManager.wifi.share.open",
        "org.freedesktop.NetworkManager.wifi.share.protected"
      ];
      if (network_actions.indexOf(action.id) >= 0 &&
          subject.isInGroup("wheel"))
      {
        return polkit.Result.YES;
      }
    });

    // Flatpak: wheel darf installieren/aktualisieren (Bazaar auf lion-pc)
    // Bazaar bleibt so passwordlos, WÄHREND auf lion-pc sudo ein Passwort verlangt
    // (security.sudo.wheelNeedsPassword = true) — bösartige Flatpak-App kann so
    // nicht über sandboxlosen/passwordlosen sudo zu Root eskalieren.
    polkit.addRule(function (action, subject) {
      if (action.id.indexOf("org.freedesktop.Flatpak.") === 0 &&
          subject.isInGroup("wheel"))
      {
        return polkit.Result.YES;
      }
    });
  '';
}
