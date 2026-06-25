{ config, pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    config = {
      vo = "gpu";
      gpu-context = "wayland";
      hwdec = "auto-safe";
      audio-device = "pipewire/GameSink";
      audio-channels = "7.1,5.1,stereo";
      ao = "pipewire";
      osc = "yes";
      border = "no";
      cursor-autohide = 1000;
    };
  };
}
