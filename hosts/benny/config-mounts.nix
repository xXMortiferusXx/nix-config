# Bind-Mounts für benny's ~/.config nach /etc/nixos/...
# Ermöglicht FHS-Sandbox-Apps (Steam etc.) direkten Zugriff auf Config-Dateien.
{ config, pkgs, ... }:

let
  user = "benny";
  homeDir = "/home/${user}";
  configBase = "/etc/nixos/home/benny/config";

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
  systemd.tmpfiles.rules = [
    "d ${homeDir}/.config 0755 ${user} users -"
  ] ++ (map (dir:
    "d ${homeDir}/.config/${dir} 0755 ${user} users -"
  ) configDirs);

  systemd.mounts = map (dir: {
    what = "${configBase}/${dir}";
    where = "${homeDir}/.config/${dir}";
    type = "none";
    options = "bind";
    wantedBy = [ "multi-user.target" ];
  }) configDirs;
}
