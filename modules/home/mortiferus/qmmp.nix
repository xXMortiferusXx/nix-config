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
