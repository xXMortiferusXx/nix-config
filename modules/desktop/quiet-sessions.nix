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
    exec ${config.programs.hyprland.package}/bin/start-hyprland >/dev/null 2>&1
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
    Exec=start-hyprland >/dev/null 2>&1
    Type=Application
    DesktopNames=Hyprland
    EOF
  '';
in {
  services.displayManager.sessionPackages = lib.mkForce [ quiet-sessions ];
}
