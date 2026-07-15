{ config, pkgs, ... }:

{
  programs.mangohud = {
    enable = true;
    enableSessionWide = false;
    settings = {
      pci_dev = "0000:01:00.0";
      legacy_layout = 1;
      font_size = 20;
      background_alpha = "0.4";
      cpu_stats = true;
      cpu_temp = true;
      cpu_mhz = true;
      cpu_color = "2E97CB";
      gpu_stats = true;
      gpu_temp = true;
      gpu_core_clock = true;
      vram = true;
      gpu_color = "2E9762";
      ram = true;
      fps = true;
      fps_metrics = "avg+0.01";
      frame_timing = true;
      toggle_hud = "Shift_R+F12";
    };
  };
}
