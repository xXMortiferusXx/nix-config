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

      # Video / Audio
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "audio/mpeg" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";

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
