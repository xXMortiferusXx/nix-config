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

      # Audio (alle von mpv registrierten Formate)
      "audio/mpeg" = "mpv.desktop";
      "audio/mp3" = "mpv.desktop";
      "audio/x-mp3" = "mpv.desktop";
      "audio/mp4" = "mpv.desktop";
      "audio/m4a" = "mpv.desktop";
      "audio/x-m4a" = "mpv.desktop";
      "audio/aac" = "mpv.desktop";
      "audio/x-aac" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "audio/vorbis" = "mpv.desktop";
      "audio/x-vorbis" = "mpv.desktop";
      "audio/x-vorbis+ogg" = "mpv.desktop";
      "audio/opus" = "mpv.desktop";
      "audio/wav" = "mpv.desktop";
      "audio/x-wav" = "mpv.desktop";
      "audio/vnd.wave" = "mpv.desktop";
      "audio/x-pn-wav" = "mpv.desktop";
      "audio/x-pn-windows-pcm" = "mpv.desktop";
      "audio/aiff" = "mpv.desktop";
      "audio/x-aiff" = "mpv.desktop";
      "audio/x-ms-wma" = "mpv.desktop";
      "audio/x-ape" = "mpv.desktop";
      "audio/x-wavpack" = "mpv.desktop";
      "audio/x-tta" = "mpv.desktop";
      "audio/ac3" = "mpv.desktop";
      "audio/eac3" = "mpv.desktop";
      "audio/vnd.dts" = "mpv.desktop";
      "audio/vnd.dts.hd" = "mpv.desktop";
      "audio/AMR" = "mpv.desktop";
      "audio/amr-wb" = "mpv.desktop";
      "audio/x-matroska" = "mpv.desktop";
      "audio/webm" = "mpv.desktop";
      "audio/vnd.rn-realaudio" = "mpv.desktop";
      "audio/x-realaudio" = "mpv.desktop";
      "audio/x-pn-realaudio" = "mpv.desktop";
      "audio/x-adpcm" = "mpv.desktop";
      "audio/x-shorten" = "mpv.desktop";
      "audio/3gpp" = "mpv.desktop";
      "audio/3gpp2" = "mpv.desktop";
      "audio/dv" = "mpv.desktop";

      # Container / Playlists (mpv übernimmt sie)
      "application/ogg" = "mpv.desktop";
      "application/x-ogg" = "mpv.desktop";
      "application/mxf" = "mpv.desktop";
      "application/x-matroska" = "mpv.desktop";
      "application/x-ogm" = "mpv.desktop";
      "application/x-ogm-audio" = "mpv.desktop";
      "application/x-ogm-video" = "mpv.desktop";
      "application/x-cue" = "mpv.desktop";
      "audio/m3u" = "mpv.desktop";
      "audio/mpegurl" = "mpv.desktop";
      "audio/x-mpegurl" = "mpv.desktop";
      "application/x-mpegurl" = "mpv.desktop";

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
