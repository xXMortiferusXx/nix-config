{ config, pkgs, ... }:

{
  security.sudo.wheelNeedsPassword = false;

  security.sudo.extraRules = [
    {
      users = [ "mortiferus" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nvidia-smi";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';
}
