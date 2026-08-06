# Hyprland Compositor + gnome-keyring als systemd-Service
# Paket-Quelle: offizieller Hyprland-Flake (github:hyprwm/Hyprland) mit hyprland.cachix.org Cache
{ inputs, config, pkgs, lib, ... }:

{
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # systemd-user-Service (Parität zu niri.service): graphical-session.target wird
  # per bindsTo als Dependency aktiviert (manueller `systemctl start` ist bei dem
  # Target verweigert), damit die Autostart-Services (noctalia, steam, discord, …)
  # starten. start-hyprland (quiet-sessions) startet diesen Service via --wait.
  systemd.user.services.hyprland = {
    restartIfChanged = false;
    # NixOS setzt sonst Environment="PATH=coreutils:…" (Minimal-PATH) auf die
    # Unit und überschreibt damit den PATH, den start-hyprland per
    # import-environment in den User-Manager importiert hat – das bricht
    # start-hyprland (execvp("Hyprland")) UND das Spawnen von Apps.
    # Gleiche Behandlung wie der niri-Modul (nixpkgs programs/wayland/niri.nix).
    enableDefaultPath = false;
    description = "Hyprland";
    bindsTo = [ "graphical-session.target" ];
    before = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
    serviceConfig = {
      # notify: Hyprland sendet READY=1 (src/Compositor.cpp, sdNotify) NACH
      # Import der Session-Env (WAYLAND_DISPLAY etc.) in den User-Manager.
      # Erst dann aktiviert systemd graphical-session.target → Autostarts
      # (discord/steam/…) feuern erst, wenn der Compositor wirklich bereit ist.
      # Parität zu niri.service. Mit Type=simple wäre graphical-session.target
      # sofort aktiv → Discord/Steam starten zu früh (kein Wayland-Socket).
      Type = "notify";
      # READY=1 kommt von Hyprland (Kindprozess von start-hyprland), nicht vom
      # Main-Prozess. Default NotifyAccess=main verwirft das → Timeout. Daher
      # alle Prozesse der CGroup als Notify-Quelle erlauben.
      NotifyAccess = "all";
      Slice = "session.slice";
      # start-hyprland (offizieller Watchdog): findet Hyprland über den
      # importierten PATH, übergibt --watchdog-fd (keine Warnung) und bleibt
      # als Main-Prozess aktiv, solange Hyprland läuft. Hyprland erbt dabei
      # NOTIFY_SOCKET von systemd und sendet sein READY=1 durch.
      ExecStart = "${config.programs.hyprland.package}/bin/start-hyprland";
    };
  };

  services.gnome.gnome-keyring.enable = true;

  # Binary Cache für den offiziellen Hyprland-Flake (verhindert lokales Kompilieren)
  # Offizielle Werte laut Hyprland-Howto (key: a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=)
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    # Nötig, damit auch Nicht-Root-Nutzer den Substituter/Keys nutzen dürfen
    trusted-users = [ "root" "@wheel" ];
  };

  environment.systemPackages = with pkgs; [
    # hyprshot überschreiben, damit es auf das Flake-Hyprland zeigt
    # (statt aufs nixpkgs-Hyprland, dessen Build aktuell kaputt ist)
    (pkgs.hyprshot.override {
      hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    })
  ];
}
