{ config, pkgs, ... }:

{
  imports = [
    ./steam.nix
    ./lutris.nix
    ./gamemode.nix
    ./gamescope.nix
    ./sunshine.nix
    ./scripts.nix
  ];

  # Controller-Touchpads als libinput ignorieren (DualSense/DualShock/Xbox)
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="input", ATTRS{name}=="*DualSense*Touchpad*", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    ACTION=="add|change", SUBSYSTEM=="input", ATTRS{name}=="*Wireless Controller Touchpad*", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    ACTION=="add|change", SUBSYSTEM=="input", ATTRS{name}=="*Xbox*Controller*", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';

  security.pam.loginLimits = [
    { domain = "@wheel"; item = "nice"; type = "-"; value = "-20"; }
  ];

  users.users.mortiferus.packages = with pkgs; [
    faugus-launcher
    heroic
    gamescope
    umu-launcher
    protonplus
  ];
}
