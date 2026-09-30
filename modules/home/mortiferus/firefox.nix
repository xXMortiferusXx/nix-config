# Firefox für mortiferus (nex) — Zen-Ersatz
#
# - Vertikale Tabs (Firefox >= 136, hier 157)
# - userChrome.css für eine Zen-artige transparente Sidebar (Blur liefert umbriel)
# - Profil wird von Home-Manager als Default angelegt; Addons/Konto/Sync bleiben
#   NICHT deklarativ, sondern leben im Profil und synchen über den Firefox-Account.
{ config, pkgs, lib, ... }:

{
  programs.firefox = {
    enable = true;

    profiles.mortiferus = {
      isDefault = true;

      settings = {
        # Vertikale Tabs + neue Sidebar
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;

        # userChrome.css erlauben (sonst wird sie ignoriert)
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Transparenz des Fensters erlauben (für die umbriel-geblurrte Sidebar)
        "browser.tabs.allow_transparent_browser" = true;
      };

      userChrome = ''
        /* Zen-artige transparente Sidebar.
           Transparenz zeigt den Desktop durch; umbriel blurt ihn (window_rule blur).
           Inhalt (Webseiten) bleibt bewusst opak. */

        #main-window {
          background: transparent !important;
          -moz-appearance: none !important;
        }

        /* Obere Toolbar transparent, damit sie nicht als solider Block klebt */
        #navigator-toolbox,
        #titlebar {
          background: transparent !important;
        }

        /* Sidebar (vertikale Tabs): leicht abgedunkelt + transparent */
        #sidebar-main,
        #sidebar-box,
        #sidebar {
          background: rgba(16, 16, 24, 0.55) !important;
          border-right: 1px solid rgba(255, 255, 255, 0.08) !important;
        }

        /* Web-Inhalt opak halten */
        #tabbrowser-tabbox,
        #tabbrowser-tabpanels,
        .browserStack {
          background: var(--lwt-accent-color, #1c1b22) !important;
        }
      '';
    };
  };
}
