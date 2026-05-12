{ config, pkgs, ... }:

{
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";

  i18n.extraLocaleSettings = {
    LC_TIME = "de_DE.UTF-8";
  };

  # Tastatur-Layout auch ohne grafische Oberfläche
  console = {
    keyMap = "de-latin1";
    useXkbConfig = false;
  };
}
