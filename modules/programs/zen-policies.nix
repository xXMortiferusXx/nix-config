# Enterprise Policies für Zen-Browser
# Deaktiviert Letterboxing, Workspace-Sync; aktiviert erweiterte Contextmenüs
{ config, pkgs, lib, ... }:

{
  environment.etc."zen/policies/policies.json".text = builtins.toJSON {
    policies = {
      Preferences = {
        "ui.context_menus.after_remote_menus" = {
          Value = true;
          Status = "locked";
        };
        "privacy.resistFingerprinting.letterboxing" = {
          Value = false;
          Status = "locked";
        };
        "zen.window-sync.enabled" = {
          Value = false;
          Status = "locked";
        };
      };
    };
  };
}
