# Firefox (Zen-Ersatz) — gemeinsam für alle Hosts/User
# Vertikale Tabs mit expand-on-hover; Addons/Konto/Sync bleiben nicht deklarativ.
{ config, ... }:

{
  programs.firefox = {
    enable = true;

    profiles.${config.home.username} = {
      isDefault = true;

      settings = {
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;

        "sidebar.visibility" = "expand-on-hover";

        "sidebar.main.tools" = "aichat,syncedtabs,history,bookmarks,opentabs";
      };
    };
  };
}
