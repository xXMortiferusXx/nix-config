# Bind-Mounts für mortiferus's ~/.config nach /etc/nixos/...
# Ermöglicht FHS-Sandbox-Apps (Steam etc.) direkten Zugriff auf Config-Dateien,
# ohne Symlink-Auflösung über /etc/nixos (im bubblewrap-Sandbox nicht erreichbar).
# Mountet beim Boot (system-level), nicht beim User-Login.
{ config, pkgs, ... }:

let
  user = "mortiferus";
  homeDir = "/home/${user}";
  configBase = "/etc/nixos/home/${user}/config";

  # Alle Config-Verzeichnisse die per bind-mount bereitgestellt werden
  configDirs = [
    "gtk-3.0"
    "gtk-4.0"
    "umbriel"
    "nvim"
    "pipewire"
    "qt5ct"
    "qt6ct"
    "xsettingsd"
  ];
in
{
  # Ziel-Verzeichnisse beim Boot erstellen (vor den Mounts).
  # WICHTIG: ~/.config selbst zuerst, sonst legt systemd-tmpfiles den
  # fehlenden Zwischen-Pfad als root:root an → Home Manager (läuft als ${user})
  # kann danach keine eigenen Dirs mehr darin anlegen ("Keine Berechtigung").
  systemd.tmpfiles.rules = [
    "d ${homeDir}/.config 0755 ${user} users -"
  ] ++ (map (dir:
    "d ${homeDir}/.config/${dir} 0755 ${user} users -"
  ) configDirs);

  # Bind-Mounts: Repo-Config → ~/.config/
  systemd.mounts = map (dir: {
    what = "${configBase}/${dir}";
    where = "${homeDir}/.config/${dir}";
    type = "none";
    options = "bind";
    wantedBy = [ "multi-user.target" ];
  }) configDirs;
}
