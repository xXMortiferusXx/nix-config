# Firefox (Zen-Ersatz) — gemeinsam für alle Hosts/User
#
# - Vertikale Tabs + „expand-on-hover" (Seitenleiste fährt beim Hover aus, wie Zen)
# - Profil wird als Default angelegt; Addons/Konto/Sync bleiben NICHT deklarativ
#   (leben im Profil, syncen über den Firefox-Account).
{ config, ... }:

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
      };
    };
  };
}
