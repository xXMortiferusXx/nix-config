{ config, pkgs, ... }:

{
  security.polkit.enable = true;

  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.noctalia.greeter.apply-appearance" &&
          subject.user == "mortiferus")
      {
        return polkit.Result.YES;
      }
    });
  '';
}
