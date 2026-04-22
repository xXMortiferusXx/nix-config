{ config, pkgs, ... }:

{
  environment.etc."xdg/kitty/kitty.conf".text = ''
    # WAYLAND
    linux_display_server wayland

    # TRANSPARENZ
    # Funktioniert da Niri background-color "transparent" gesetzt hat
    background_opacity 0.85
    dynamic_background_opacity yes

    # LOOK & FEEL
    font_family      FiraCode Nerd Font
    bold_font        FiraCode Nerd Font Bold
    italic_font      FiraCode Nerd Font Italic
    bold_italic_font FiraCode Nerd Font Bold Italic
    font_size        11.0
    cursor_shape     beam
    cursor_blink_interval 0.5
    cursor_stop_blinking_after 15.0
    window_padding_width 8

    # CURSOR (konsistent mit home.nix GTK/Qt Einstellungen)
    linux_cursor_theme Bibata-Modern-Classic
    linux_cursor_theme_size 24

    # SCHRIFT-RENDERING
    adjust_line_height  0
    adjust_column_width 0
    disable_ligatures   never

    # PERFORMANCE (Legion 165Hz)
    repaint_delay    6
    input_delay      1
    sync_to_monitor  yes

    # SCROLLBACK
    scrollback_lines 10000
    scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER

    # URL-HANDLING
    url_style         curly
    open_url_with     default
    detect_urls       yes
    url_prefixes      file ftp ftps git http https irc ircs kitty mailto news sftp ssh

    # BELL
    enable_audio_bell no
    visual_bell_duration 0.1
    window_alert_on_bell yes

    # TABS
    tab_bar_edge              bottom
    tab_bar_style             powerline
    tab_powerline_style       slanted
    tab_title_template        "{index}: {title}"
    active_tab_font_style     bold
    inactive_tab_font_style   normal

    # WINDOW
    # remember_window_size deaktiviert - Niri verwaltet Fenstergrößen selbst (Tiling)
    confirm_os_window_close 0
    remember_window_size    no
    # scale ist unter Wayland/Niri besser als static
    resize_draw_strategy    scale

    # TASTENKÜRZEL
    # Tabs
    map ctrl+shift+t new_tab_with_cwd
    map ctrl+shift+w close_tab
    map ctrl+shift+right next_tab
    map ctrl+shift+left  previous_tab
    # Splits
    map ctrl+shift+enter new_window_with_cwd
    map ctrl+shift+] next_window
    map ctrl+shift+[ previous_window
    # Schriftgröße
    map ctrl+shift+equal  change_font_size all +1.0
    map ctrl+shift+minus  change_font_size all -1.0
    map ctrl+shift+0      change_font_size all 0
    # Clipboard
    map ctrl+shift+c copy_to_clipboard
    map ctrl+shift+v paste_from_clipboard

    # FARBEN
    foreground #dddddd
    background #000000

    # Cursor
    cursor           #dddddd
    cursor_text_color #000000

    # Auswahl
    selection_foreground #000000
    selection_background #dddddd

    # Normales Schwarz
    color0  #1a1a1a
    color8  #444444

    # Rot
    color1  #cc3333
    color9  #ff5555

    # Grün
    color2  #33cc33
    color10 #55ff55

    # Gelb
    color3  #ccaa00
    color11 #ffdd00

    # Blau
    color4  #3366cc
    color12 #5588ff

    # Magenta
    color5  #aa33cc
    color13 #dd55ff

    # Cyan
    color6  #33aacc
    color14 #55ddff

    # Weiß
    color7  #dddddd
    color15 #ffffff
  '';
}
