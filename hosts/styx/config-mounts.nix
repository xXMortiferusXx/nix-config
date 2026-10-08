# Bind-Mounts für backbone's ~/.config nach /etc/nixos/... (system-level beim Boot).
# FHS-Sandbox-Apps brauchen direkten Zugriff ohne Symlink über /etc/nixos.
{ config, pkgs, ... }:

let
  user = "backbone";
  homeDir = "/home/${user}";
  configBase = "/etc/nixos/home/${user}/config";

  configDirs = [
    "umbriel"
    "nvim"
  ];
in
{
  # WICHTIG: ~/.config zuerst anlegen, sonst wird der Zwischen-Pfad root:root.
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
