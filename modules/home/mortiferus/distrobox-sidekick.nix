{ config, pkgs, lib, ... }:

let
  sidekickScript = pkgs.writeShellScriptBin "sidekick" ''
    set -euo pipefail

    APPIMAGE="/home/mortiferus/Apps/Sidekick-linux-x64.AppImage"
    EXTRACT_DIR="/tmp/sidekick-extract"
    CONTAINER_NAME="sidekick-arch"

    # Prüfe, ob AppImage existiert
    if [ ! -f "$APPIMAGE" ]; then
      echo "❌ Sidekick AppImage nicht gefunden: $APPIMAGE"
      echo "Bitte Sidekick-linux-x64.AppImage nach ~/Apps/ kopieren."
      exit 1
    fi

    # Prüfe, ob Container existiert - erstelle ihn falls nötig
    if ! ${pkgs.podman}/bin/podman ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
      echo "🐳 Sidekick-Container nicht gefunden. Erstelle neu..."
      ${pkgs.distrobox}/bin/distrobox create --name "$CONTAINER_NAME" --image docker.io/archlinux:latest --yes
      echo "✅ Container erstellt"
    fi

    # Prüfe, ob Dependencies installiert sind - installiere falls nötig
    if ! ${pkgs.distrobox}/bin/distrobox enter "$CONTAINER_NAME" -- bash -c "which xsel >/dev/null 2>&1 && pacman -Q webkit2gtk-4.1 >/dev/null 2>&1" 2>/dev/null; then
      echo "📦 Dependencies fehlen. Installiere xsel und webkit2gtk-4.1..."
      ${pkgs.distrobox}/bin/distrobox enter "$CONTAINER_NAME" -- sudo pacman -Sy --needed --noconfirm xsel webkit2gtk-4.1
      echo "✅ Dependencies installiert"
    fi

    # Entpacke AppImage im Container (nur beim ersten Mal)
    if ! ${pkgs.distrobox}/bin/distrobox enter "$CONTAINER_NAME" -- bash -c "[ -d '$EXTRACT_DIR' ]" 2>/dev/null; then
      echo "📂 Entpacke Sidekick AppImage..."
      ${pkgs.distrobox}/bin/distrobox enter "$CONTAINER_NAME" -- bash -c "
        cd /tmp
        '$APPIMAGE' --appimage-extract >/dev/null
        mv squashfs-root '$EXTRACT_DIR'
      "
      echo "✅ AppImage entpackt"
    fi

    # Starte Sidekick im Container
    echo "🚀 Starte Sidekick..."
    exec ${pkgs.distrobox}/bin/distrobox enter "$CONTAINER_NAME" -- bash -c "
      export GDK_BACKEND=x11
      export WEBKIT_DISABLE_COMPOSITING_MODE=1
      export WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1
      exec '$EXTRACT_DIR/usr/bin/Sidekick' '\$@'
    " "$@"
  '';
in {
  # Sidekick-Befehl verfügbar machen
  home.packages = [ sidekickScript ];

  # ~/.local/bin zum PATH hinzufügen
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Desktop Entry für Anwendungsmenü
  xdg.desktopEntries.sidekick = {
    name = "Sidekick";
    comment = "POE/POE2 Price Checker";
    exec = "sidekick";
    icon = "/home/mortiferus/Apps/sidekick-linux.png";
    terminal = false;
    categories = [ "Game" ];
    startupNotify = true;
  };

  # Automatische Updates für Sidekick-Container (nur wenn Container existiert)
  home.activation.sidekick-container-update = lib.mkAfter ''
    if ${pkgs.podman}/bin/podman ps -a --format "{{.Names}}" | grep -q "^sidekick-arch$"; then
      echo "Updating sidekick-arch container..."
      ${pkgs.distrobox}/bin/distrobox enter sidekick-arch -- sudo pacman -Syu --noconfirm 2>/dev/null || true
    fi
  '';

  # Wöchentlicher systemd-Timer für Updates
  systemd.user.services.sidekick-update = {
    Unit = {
      Description = "Update Sidekick Arch Container";
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "sidekick-update" ''
        if ${pkgs.podman}/bin/podman ps -a --format "{{.Names}}" | grep -q "^sidekick-arch$"; then
          ${pkgs.distrobox}/bin/distrobox enter sidekick-arch -- sudo pacman -Syu --noconfirm
        fi
      '';
    };
  };

  systemd.user.timers.sidekick-update = {
    Unit = {
      Description = "Weekly Sidekick Container Update";
    };
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
