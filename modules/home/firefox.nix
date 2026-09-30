# Firefox (Zen-Ersatz) — gemeinsam für alle Hosts/User
#
# - Vertikale Tabs + „expand-on-hover" (Seitenleiste fährt beim Hover aus, wie Zen)
# - Transparenz für die umbriel-geblurrte Sidebar
# - Profil wird als Default angelegt; Addons/Konto/Sync bleiben NICHT deklarativ
#   (leben im Profil, syncen über den Firefox-Account).
{ config, pkgs, lib, ... }:

{
  programs.firefox = {
    enable = true;

    profiles.${config.home.username} = {
      isDefault = true;

      settings = {
        # Vertikale Tabs + neue Sidebar
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;

        # Seitenleiste einklappen und beim Hover ausfahren (Zen-Compact-Verhalten)
        "sidebar.visibility" = "expand-on-hover";

        # Welche Werkzeuge in der Sidebar angezeigt werden
        "sidebar.main.tools" = "aichat,syncedtabs,history,bookmarks,opentabs";

        # userChrome.css erlauben (sonst wird sie ignoriert)
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Transparenz des Fensters (für die umbriel-geblurrte Sidebar)
        "browser.tabs.allow_transparent_browser" = true;
        "widget.transparent-windows" = true;
        "widget.wayland.transparent-background" = true;
      };

      userChrome = ''
        /* Zen-artige transparente Sidebar.
           Transparenz zeigt den Desktop durch; umbriel blurt ihn (window_rule blur).
           Web-Inhalt bleibt bewusst opak.
           (Selektoren für Firefox 157 geprüft: sidebar-box/sidebar existieren,
            sidebar-main/titlebar NICHT.) */

        @-moz-document url-prefix("chrome://browser/content/browser.xhtml") {
          :root {
            background: transparent !important;
          }

          #main-window {
            background: transparent !important;
            -moz-appearance: none !important;
            appearance: none !important;
          }

          #navigator-toolbox,
          #TabsToolbar {
            background: transparent !important;
          }

          /* Sidebar (vertikale Tabs): leicht abgedunkelt + transparent */
          #sidebar-box,
          #sidebar {
            background: rgba(15, 15, 25, 0.5) !important;
            border-right: 1px solid rgba(255, 255, 255, 0.08) !important;
          }

          /* Web-Inhalt opak halten */
          #tabbrowser-tabbox,
          #tabbrowser-tabpanels {
            background: #1c1b22 !important;
          }
        }
      '';
    };
  };
}
