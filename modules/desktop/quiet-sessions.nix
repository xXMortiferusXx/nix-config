# Unterdrückt doppelte Display-Manager-Einträge
# Erzeugt saubere .desktop-Dateien für niri + hyprland (stdout >/dev/null)
{ config, pkgs, lib, ... }:
let
  quiet-sessions = pkgs.runCommand "quiet-sessions" {
    providedSessions = [ "niri" "hyprland" ];
  } ''
    mkdir -p $out/bin $out/share/wayland-sessions

    cat > $out/bin/start-hyprland << 'SCRIPT'
    #!/bin/sh
    # Wie niri-session: Environment importieren und hyprland.service starten.
    # hyprland.service hat BindsTo=graphical-session.target → das Target wird als
    # Dependency aktiviert (manueller `systemctl start` ist verweigert) und damit
    # starten die systemd-user-Services (noctalia, steam, discord, ...).
    if systemctl --user -q is-active hyprland.service; then
      exit 1
    fi
    systemctl --user reset-failed >/dev/null 2>&1
    systemctl --user import-environment >/dev/null 2>&1
    dbus-update-activation-environment --all >/dev/null 2>&1
    systemctl --user --wait start hyprland.service >/dev/null 2>&1
    status=$?
    # Parität zu niri-shutdown.target: beim Logout graphical-session.target
    # stoppen, damit Autostart-Services (noctalia, steam, discord, Portale) mit
    # veralteter Env nicht im User-Manager weiterlaufen (nächste Session startet
    # sie frisch über das Target).
    systemctl --user stop graphical-session.target >/dev/null 2>&1
    systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP >/dev/null 2>&1
    exit $status
    SCRIPT
    chmod +x $out/bin/start-hyprland

    cat > $out/share/wayland-sessions/niri.desktop <<EOF
    [Desktop Entry]
    Name=Niri
    Comment=A scrollable-tiling Wayland compositor
    Exec=niri-session >/dev/null 2>&1
    Type=Application
    DesktopNames=niri
    EOF

    cat > $out/share/wayland-sessions/hyprland.desktop <<EOF
    [Desktop Entry]
    Name=Hyprland
    Comment=Hyprland
    Exec=$out/bin/start-hyprland >/dev/null 2>&1
    Type=Application
    DesktopNames=Hyprland
    EOF
  '';
in {
  services.displayManager.sessionPackages = lib.mkForce [ quiet-sessions ];
}
