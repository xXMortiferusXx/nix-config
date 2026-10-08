# Standard-Programme (XDG MIME-Defaults) — gemeinsam für nex / lion / benny.
# Enthält nur universelle Defaults (Apps auf allen drei Hosts installiert).
{ config, ... }:

{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Browser
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

      # Video
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

      # Audio — Hauptformate an Amberol
      "audio/mpeg" = "io.bassi.Amberol.desktop";
      "audio/mp3" = "io.bassi.Amberol.desktop";
      "audio/x-mp3" = "io.bassi.Amberol.desktop";
      "audio/x-mpeg" = "io.bassi.Amberol.desktop";
      "audio/x-mpg" = "io.bassi.Amberol.desktop";
      "audio/mp4" = "io.bassi.Amberol.desktop";
      "audio/m4a" = "io.bassi.Amberol.desktop";
      "audio/x-m4a" = "io.bassi.Amberol.desktop";
      "audio/aac" = "io.bassi.Amberol.desktop";
      "audio/x-aac" = "io.bassi.Amberol.desktop";
      "audio/flac" = "io.bassi.Amberol.desktop";
      "audio/x-flac" = "io.bassi.Amberol.desktop";
      "audio/ogg" = "io.bassi.Amberol.desktop";
      "audio/vorbis" = "io.bassi.Amberol.desktop";
      "audio/x-vorbis" = "io.bassi.Amberol.desktop";
      "audio/x-vorbis+ogg" = "io.bassi.Amberol.desktop";
      "audio/opus" = "io.bassi.Amberol.desktop";
      "audio/x-opus+ogg" = "io.bassi.Amberol.desktop";
      "audio/wav" = "io.bassi.Amberol.desktop";
      "audio/x-wav" = "io.bassi.Amberol.desktop";
      "audio/vnd.wave" = "io.bassi.Amberol.desktop";
      "audio/x-pn-wav" = "io.bassi.Amberol.desktop";
      "audio/aiff" = "io.bassi.Amberol.desktop";
      "audio/x-aiff" = "io.bassi.Amberol.desktop";
      "audio/x-pn-aiff" = "io.bassi.Amberol.desktop";
      "audio/x-ape" = "io.bassi.Amberol.desktop";
      "audio/x-wavpack" = "io.bassi.Amberol.desktop";
      "audio/x-speex" = "io.bassi.Amberol.desktop";

      # Audio — Formate, die Amberol nicht abdeckt -> mpv
      "audio/x-pn-windows-pcm" = "mpv.desktop";
      "audio/x-ms-wma" = "mpv.desktop";
      "audio/x-tta" = "mpv.desktop";
      "audio/x-musepack" = "mpv.desktop";
      "audio/x-shorten" = "mpv.desktop";
      "audio/x-it" = "mpv.desktop";
      "audio/x-mod" = "mpv.desktop";
      "audio/x-s3m" = "mpv.desktop";
      "audio/x-stm" = "mpv.desktop";
      "audio/x-xm" = "mpv.desktop";
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
      "audio/3gpp" = "mpv.desktop";
      "audio/3gpp2" = "mpv.desktop";
      "audio/dv" = "mpv.desktop";
      "x-content/audio-cdda" = "mpv.desktop";

      # Container / Playlists
      "application/ogg" = "io.bassi.Amberol.desktop";
      "application/x-ogg" = "io.bassi.Amberol.desktop";
      "audio/m3u" = "io.bassi.Amberol.desktop";
      "audio/mpegurl" = "io.bassi.Amberol.desktop";
      "audio/x-mpegurl" = "io.bassi.Amberol.desktop";
      "application/x-cue" = "mpv.desktop";
      "audio/x-scpls" = "mpv.desktop";
      "application/x-mpegurl" = "mpv.desktop";
      "application/mxf" = "mpv.desktop";
      "application/x-matroska" = "mpv.desktop";
      "application/x-ogm" = "mpv.desktop";
      "application/x-ogm-audio" = "mpv.desktop";
      "application/x-ogm-video" = "mpv.desktop";

      # Bilder
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
