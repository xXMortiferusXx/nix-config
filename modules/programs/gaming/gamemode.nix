{ config, pkgs, ... }:

{
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        reaper_freq = 5;
        desiredgov = "performance";
        softrealtime = "off";
        renice = -10;
        ioprio = 0;
        inhibit_screensaver = 1;
        disable_splitlock = 1;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
      };
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if ((action.id == "com.feralinteractive.GameMode.governor-helper" ||
           action.id == "com.feralinteractive.GameMode.gpu-helper" ||
           action.id == "com.feralinteractive.GameMode.cpu-helper" ||
           action.id == "com.feralinteractive.GameMode.procsys-helper") &&
          subject.isInGroup("gamemode"))
      {
        return polkit.Result.YES;
      }
    });
  '';
}
