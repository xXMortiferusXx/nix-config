# qmmp — vorgefertigte Standard-Konfiguration (nex/mortiferus).
#
# Warum Seed-once statt vollverwalteter Datei:
#   qmmp schreibt seine Config bei jedem Beenden selbst neu (Fenstergeometrie,
#   Wiedergabeliste, zuletzt geoeffnete Ordner …). Eine von Home-Manager
#   gesetzte Read-only-Symlink-Datei wuerde das verhindern. Deshalb: beim ersten
#   Mal eine gute Vorlage setzen; danach gehoert die Datei qmmp/User.
#
#   -> Existiert ~/.config/qmmp/qmmp.conf bereits, passiert NICHTS.
#   -> Zum Zuruecksetzen auf die Vorlage: Datei loeschen und neu schalten.
#
# Wichtige Vorlagen-Inhalte:
#   - Ui/current_plugin=qsui    -> EIN Fenster, andockbare Widgets
#                                 (statt Skinned-UI mit 3 getrennten Fenstern)
#   - Output/current_plugin=pipewire -> passt zur PipeWire-Pipeline (GC7)
#   - ReplayGain an, sanftes Dithering, 24/16-bit
{ config, pkgs, lib, ... }:

let
  qmmpDefaults = pkgs.writeText "qmmp-default.conf" ''
    [%General]
    default_pl_name=Wiedergabeliste
    last_dir=$HOME
    locale=auto
    resume_on_startup=true
    resume_playback=true
    resume_playback_time=0
    use_default_pl=false

    [Ui]
    current_plugin=qsui

    [Output]
    current_plugin=pipewire
    buffer_size=1000
    format=2
    dithering=true
    software_volume=false
    volume_step=5
    average_bitrate=false

    [PlayList]
    autosave=true
    clear_previous=false
    convert_twenty=true
    convert_underscore=true
    groups=false
    lines_per_group=1
    load_metadata=true
    no_advance=false
    read_metadata_for_playlist=true
    repeate_list=false
    repeate_track=false
    shuffle=false
    skip_existing_tracks=false
    transit_between_playlists=false
    pl_show_numbers=true
    pl_show_lengths=true
    pl_show_header=true
    pl_show_tabs=true
    pl_smooth_scrolling=true
    show_menubar=true
    show_tabs=true

    [Simple]
    always_on_top=false
    block_dockwidgets=false
    block_toolbars=false
    fsbrowser_quick_search=true
    fsbrowser_tree_mode=false
    hide_on_close=false
    show_menubar=true
    show_tabs=true
    start_hidden=false
    use_system_fonts=true
    pl_show_numbers=true
    pl_show_lengths=true
    pl_show_header=true
    pl_smooth_scrolling=true
    # Fenstergeometrie + Dock-Layout (Playlists/Cover/Files links gestapelt,
    # Playlist zentral, Visualisierung unten; Waveform-Seekbar ausgeblendet).
    # Erzeugt mit Qt 6.11.2 (== qmmp-Build); passt die Qt-Version nicht, ignoriert
    # qmmp den State und faellt auf sein Default-Layout zurueck.
    mw_geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\0\0\0\0\0\0\0\x3\xaf\0\0\x4\x1\0\0\0\0\0\0\0\0\0\0\x3\xaf\0\0\x4\x1\0\0\0\0\0\0\0\0\a\x80\0\0\0\0\0\0\0\0\0\0\x3\xaf\0\0\x4\x1)
    mw_state="@ByteArray(\0\0\0\xff\0\0\0\0\xfd\0\0\0\x3\0\0\0\0\0\0\x1\0\0\0\x3,\xfc\x2\0\0\0\x3\xfb\0\0\0&\0p\0l\0\x61\0y\0l\0i\0s\0t\0s\0\x44\0o\0\x63\0k\0W\0i\0\x64\0g\0\x65\0t\x1\0\0\0?\0\0\x1\x8c\0\0\0\x7f\0\xff\xff\xff\xfb\0\0\0\x1e\0\x63\0o\0v\0\x65\0r\0\x44\0o\0\x63\0k\0W\0i\0\x64\0g\0\x65\0t\x1\0\0\x1\xd1\0\0\0\x15\0\0\0\x15\0\xff\xff\xff\xfb\0\0\0(\0\x66\0i\0l\0\x65\0S\0y\0s\0t\0\x65\0m\0\x44\0o\0\x63\0k\0W\0i\0\x64\0g\0\x65\0t\x1\0\0\x1\xec\0\0\x1\x7f\0\0\0w\0\xff\xff\xff\0\0\0\x2\0\0\0\0\0\0\0\0\xfc\x1\0\0\0\x1\xfb\0\0\0\x32\0w\0\x61\0v\0\x65\0\x66\0o\0r\0m\0S\0\x65\0\x65\0k\0\x42\0\x61\0r\0\x44\0o\0\x63\0k\0W\0i\0\x64\0g\0\x65\0t\0\0\0\0\0\xff\xff\xff\xff\0\0\0\x36\0\xff\xff\xff\0\0\0\x3\0\0\x3\xb0\0\0\0y\xfc\x1\0\0\0\x1\xfb\0\0\0$\0\x61\0n\0\x61\0l\0y\0z\0\x65\0r\0\x44\0o\0\x63\0k\0W\0i\0\x64\0g\0\x65\0t\x1\0\0\0\0\0\0\x3\xb0\0\0\0O\0\xff\xff\xff\0\0\x2\xaa\0\0\x3,\0\0\0\x4\0\0\0\x4\0\0\0\b\0\0\0\b\xfc\0\0\0\x1\0\0\0\x2\0\0\0\x1\0\0\0Z\0T\0o\0o\0l\0\x62\0\x61\0r\0{\0\x36\0\x38\0\x33\0\x36\0\x33\0\x61\0\x30\0\x62\0-\0\x66\0\x32\0\x63\0\x64\0-\0\x34\0\x36\0\x32\0\x61\0-\0\x38\0\x37\0\x63\0\x61\0-\0\x65\0\x33\0\x30\0\x38\0\x39\0\x64\0\x62\0\x32\0\x31\0\x35\0\x36\0\x31\0}\x1\0\0\0\0\xff\xff\xff\xff\0\0\0\0\0\0\0\0)"

    [ReplayGain]
    mode=0
    preamp=0
    default_gain=0
    prevent_clipping=true

    [Equalizer]
    two_passes=true

    [Misc]
    determine_file_by_content=false
    '';
in
{
  home.activation.qmmpDefaultConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    qmmpDir="$HOME/.config/qmmp"
    if [ ! -e "$qmmpDir/qmmp.conf" ]; then
      run mkdir -p "$qmmpDir"
      run cp ${qmmpDefaults} "$qmmpDir/qmmp.conf"
      run chmod u+w "$qmmpDir/qmmp.conf"
    fi
  '';
}
