{ config, pkgs, ... }:

{
  # 1. Sicherstellen, dass Kitty installiert ist
  environment.systemPackages = [ pkgs.kitty ];

  # 2. Die Konfigurationsdatei direkt schreiben
  environment.etc."xdg/kitty/kitty.conf".text = ''
    # TRANSPARENZ
    background_opacity 0.85
    dynamic_background_opacity yes
    
    # LOOK & FEEL
    font_family      FiraCode Nerd Font
    font_size        11.0
    cursor_shape     beam
    window_padding_width 4
    
    # PERFORMANCE (Legion 165Hz)
    repaint_delay    6
    input_delay      1
    sync_to_monitor  yes

    # WINDOW
    confirm_os_window_close 0
    
    # Ein schlichtes dunkles Theme (Kitty Standard-nah)
    foreground #dddddd
    background #000000
  '';
}
