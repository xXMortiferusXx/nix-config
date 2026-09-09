# Bind-Mounts für lion's ~/.config nach /etc/nixos/...
# Ermöglicht FHS-Sandbox-Apps (Steam etc.) direkten Zugriff auf Config-Dateien,
# ohne Symlink-Auflösung über /etc/nixos (im bubblewrap-Sandbox nicht erreichbar).
# Mountet beim Boot (system-level), nicht beim User-Login.
{ config, pkgs, ... }:

let
  user = "lion";
  homeDir = "/home/${user}";
  configBase = "/etc/nixos/home/lion/config";

  # Alle Config-Verzeichnisse die per bind-mount bereitgestellt werden
  # (Umbriel + Theming 1:1 von nex; pipewire-HRIR von mortiferus bewusst NICHT)
  configDirs = [
    "gtk-3.0"
    "gtk-4.0"
    "umbriel"
    "nvim"
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
    # Gaming-Drive gehört dem User, sonst kann Steam (läuft als ${user})
    # dort keine SteamLibrary anlegen.
    "z /gaming 0755 ${user} users -"
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