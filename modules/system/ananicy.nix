# ananicy-cpp: Auto-Nice-Daemon mit CachyOS-Regeln
# Setzt automatisch nice/ionice/cgroup/oom pro Prozess basierend auf Regelwerk
# Siehe: https://gitlab.com/ananicy-cpp/ananicy-cpp
# Regeln: https://github.com/CachyOS/ananicy-rules
{ config, pkgs, lib, ... }:

{
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    settings = {
      check_freq = 15;
      loglevel = "warn";
      log_applied_rule = false;
      cgroup_realtime_workaround = lib.mkForce false;
      apply_cgroup = lib.mkForce false;
    };
  };
}
