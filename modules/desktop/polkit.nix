# Polkit-Regeln
# - noctalia-greeter: apply-appearance passwordlos für mortiferus + backbone
# - NetworkManager: wheel-Gruppe darf Netzwerk verwalten ohne Passwort
{ config, pkgs, ... }:

{
  security.polkit.enable = true;

  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.noctalia.greeter.apply-appearance" &&
          (subject.user == "mortiferus" || subject.user == "backbone"))
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
  '';
}
