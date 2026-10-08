# MangoHud - Steam-artiges In-Game-Overlay (nur nex / mortiferus), erzeugt MangoHud.conf.
# Kompakt & horizontal, NVIDIA-only (AMD-iGPU ausgeblendet), zentriert via offset_x.
# Bewusst nicht gesetzt: cpu_power, gpu_junction_temp/voltage/fan (auf NVIDIA/RAPL nicht verfuegbar).
{ ... }:

{
  programs.mangohud = {
    enable = true;
    enableSessionWide = false;
    settings = {
      # MangoHud top-center ist im horizontalen Modus fehlerhaft -> top-left + offset_x.
      position = "top-left";
      offset_x = 330;
      offset_y = 6;
      horizontal = true;

      # Aussehen (Steam-Look)
      background_alpha = 0.4;
      background_color = "000000";
      round_corners = 6;
      font_size = 16;
      text_color = "FFFFFF";
      text_outline = true;
      text_outline_color = "000000";
      text_outline_thickness = 1.5;
      alpha = 1.0;

      # Nur NVIDIA RTX 3070; AMD-iGPU ausblenden
      pci_dev = "0000:01:00.0";

      # FPS + Frametime
      fps = true;
      frametime = true;
      frame_timing = true;
      fps_color_change = true;
      fps_value = "30,60";

      # GPU
      gpu_stats = true;
      gpu_temp = true;
      gpu_core_clock = true;
      gpu_mem_clock = true;
      gpu_power = true;
      vram = true;
      gpu_load_change = true;
      gpu_load_value = "60,90";

      # CPU (nur Gesamtlast)
      cpu_stats = true;
      cpu_temp = true;
      cpu_mhz = true;
      cpu_load_change = true;
      cpu_load_value = "60,90";

      # System
      ram = true;
      battery = true;
    };
  };
}
