# Standard-Programme (XDG MIME-Defaults) — deklarativ für nex/mortiferus.
#
# Hintergrund: Bisher lag die Zuordnung nur in der handgeschriebenen,
# Home-Manager-unverwalteten ~/.config/mimeapps.list. Dort stand noch der
# tote `zen-beta.desktop` als Browser (Zen wurde durch Firefox ersetzt), der
# gar nicht mehr installiert war. Diese Datei wird jetzt von Home-Manager
# verwaltet und ist die einzige Quelle der Wahrheit.
#
# WICHTIG: Änderungen hier treten in Kraft, weil xdg.mimeApps die Datei
# generiert. Wird Zen/Firefox o.ä. gewechselt, hier anpassen — nicht mehr
# manuell in mimeapps.list.
{ config, ... }:

{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Browser (Zen -> Firefox abgelöst)
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "application/xml" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";

      # E-Mail
      "x-scheme-handler/mailto" = "thunderbird.desktop";
      "message/rfc822" = "thunderbird.desktop";

      # PDF
      "application/pdf" = "org.pwmt.zathura-pdf-mupdf.desktop";

      # Text / Code
      "text/plain" = "nvim.desktop";
      "application/x-shellscript" = "nvim.desktop";

      # Video (alle von mpv registrierten Formate)
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/mkv" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/mpeg" = "mpv.desktop";
      "video/x-mpeg2" = "mpv.desktop";
      "video/x-mpeg3" = "mpv.desktop";
      "video/mp4v-es" = "mpv.desktop";
      "video/x-m4v" = "mpv.desktop";
      "video/divx" = "mpv.desktop";
      "video/vnd.divx" = "mpv.desktop";
      "video/msvideo" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
      "video/avi" = "mpv.desktop";
      "video/x-avi" = "mpv.desktop";
      "video/vnd.avi" = "mpv.desktop";
      "video/ogg" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/x-ms-wmv" = "mpv.desktop";
      "video/x-ms-wmx" = "mpv.desktop";
      "video/x-ms-wvxvideo" = "mpv.desktop";
      "video/x-ms-asf" = "mpv.desktop";
      "video/x-ms-afs" = "mpv.desktop";
      "video/vnd.rn-realvideo" = "mpv.desktop";
      "video/x-flic" = "mpv.desktop";
      "video/fli" = "mpv.desktop";
      "video/x-flc" = "mpv.desktop";
      "video/flv" = "mpv.desktop";
      "video/x-flv" = "mpv.desktop";
      "video/x-theora" = "mpv.desktop";
      "video/x-theora+ogg" = "mpv.desktop";
      "video/x-ogm" = "mpv.desktop";
      "video/x-ogm+ogg" = "mpv.desktop";
      "video/mp2t" = "mpv.desktop";
      "video/vnd.mpegurl" = "mpv.desktop";
      "video/3gp" = "mpv.desktop";
      "video/3gpp" = "mpv.desktop";
      "video/3gpp2" = "mpv.desktop";
      "video/dv" = "mpv.desktop";

      # Audio (alle von qmmp registrierten Formate)
      "audio/mpeg" = "qmmp.desktop";
      "audio/mp3" = "qmmp.desktop";
      "audio/x-mp3" = "qmmp.desktop";
      "audio/x-mpeg" = "qmmp.desktop";
      "audio/mp4" = "qmmp.desktop";
      "audio/m4a" = "qmmp.desktop";
      "audio/x-m4a" = "qmmp.desktop";
      "audio/aac" = "qmmp.desktop";
      "audio/x-aac" = "qmmp.desktop";
      "audio/flac" = "qmmp.desktop";
      "audio/ogg" = "qmmp.desktop";
      "audio/vorbis" = "qmmp.desktop";
      "audio/x-vorbis" = "qmmp.desktop";
      "audio/x-vorbis+ogg" = "qmmp.desktop";
      "audio/opus" = "qmmp.desktop";
      "audio/wav" = "qmmp.desktop";
      "audio/x-wav" = "qmmp.desktop";
      "audio/vnd.wave" = "qmmp.desktop";
      "audio/x-pn-wav" = "qmmp.desktop";
      "audio/x-pn-windows-pcm" = "qmmp.desktop";
      "audio/aiff" = "qmmp.desktop";
      "audio/x-aiff" = "qmmp.desktop";
      "audio/x-ms-wma" = "qmmp.desktop";
      "audio/x-ape" = "qmmp.desktop";
      "audio/x-wavpack" = "qmmp.desktop";
      "audio/x-tta" = "qmmp.desktop";
      "audio/x-musepack" = "qmmp.desktop";
      "audio/x-shorten" = "qmmp.desktop";
      "audio/x-it" = "qmmp.desktop";
      "audio/x-mod" = "qmmp.desktop";
      "audio/x-s3m" = "qmmp.desktop";
      "audio/x-stm" = "qmmp.desktop";
      "audio/x-xm" = "qmmp.desktop";
      "audio/ac3" = "qmmp.desktop";
      "audio/eac3" = "qmmp.desktop";
      "audio/vnd.dts" = "qmmp.desktop";
      "audio/vnd.dts.hd" = "qmmp.desktop";
      "audio/AMR" = "qmmp.desktop";
      "audio/amr-wb" = "qmmp.desktop";
      "audio/x-matroska" = "qmmp.desktop";
      "audio/webm" = "qmmp.desktop";
      "audio/vnd.rn-realaudio" = "qmmp.desktop";
      "audio/x-realaudio" = "qmmp.desktop";
      "audio/x-pn-realaudio" = "qmmp.desktop";
      "audio/x-adpcm" = "qmmp.desktop";
      "audio/3gpp" = "qmmp.desktop";
      "audio/3gpp2" = "qmmp.desktop";
      "audio/dv" = "qmmp.desktop";
      "x-content/audio-cdda" = "qmmp.desktop";

      # Container / Playlists
      "application/ogg" = "qmmp.desktop";
      "application/x-ogg" = "qmmp.desktop";
      "application/x-cue" = "qmmp.desktop";
      "audio/m3u" = "qmmp.desktop";
      "audio/mpegurl" = "qmmp.desktop";
      "audio/x-mpegurl" = "qmmp.desktop";
      "audio/x-scpls" = "qmmp.desktop";
      "application/x-mpegurl" = "mpv.desktop";
      "application/mxf" = "mpv.desktop";
      "application/x-matroska" = "mpv.desktop";
      "application/x-ogm" = "mpv.desktop";
      "application/x-ogm-audio" = "qmmp.desktop";
      "application/x-ogm-video" = "mpv.desktop";

      # Bilder (alle von Loupe unterstützten Formate)
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "image/bmp" = "org.gnome.Loupe.desktop";
      "image/gif" = "org.gnome.Loupe.desktop";
      "image/webp" = "org.gnome.Loupe.desktop";
      "image/avif" = "org.gnome.Loupe.desktop";
      "image/jxl" = "org.gnome.Loupe.desktop";
      "image/heic" = "org.gnome.Loupe.desktop";
      "image/tiff" = "org.gnome.Loupe.desktop";
      "image/jp2" = "org.gnome.Loupe.desktop";
      "image/svg+xml" = "org.gnome.Loupe.desktop";

      # Dateimanager
      "inode/directory" = "thunar.desktop";
    };
  };
}
