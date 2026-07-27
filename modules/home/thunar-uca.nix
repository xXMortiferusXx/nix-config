# Thunar Custom Actions (UCA) – Archiv-Entpack-Menü
# Legt ~/.config/Thunar/uca.xml mit Entpacken-Untermenü an
# Wird von mortiferus + backbone Home-Manager importiert
{ config, pkgs, ... }:

let
  archivePatterns = "*.zip;*.tar.gz;*.tgz;*.tar.bz2;*.tbz2;*.tar.xz;*.txz;*.tar;*.7z;*.rar";
in
{
  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
      <action>
        <icon>package-x-generic</icon>
        <name>Hier entpacken</name>
        <submenu>Entpacken</submenu>
        <command>${pkgs.bash}/bin/bash -c 'cd "%d" && thunar-extract "%f" "%d" here'</command>
        <description>Archiv im aktuellen Ordner entpacken</description>
        <patterns>${archivePatterns}</patterns>
        <other-files/>
      </action>
      <action>
        <icon>folder-open</icon>
        <name>In Ordner entpacken...</name>
        <submenu>Entpacken</submenu>
        <command>${pkgs.bash}/bin/bash -c 'cd "%d" && thunar-extract "%f" "%d" tofolder'</command>
        <description>Archiv in neuen Unterordner entpacken</description>
        <patterns>${archivePatterns}</patterns>
        <other-files/>
      </action>
    </actions>
  '';
}
