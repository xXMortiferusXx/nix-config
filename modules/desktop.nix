{ config, pkgs, lib, ... }:

{
  # ────────────── Desktop-Umgebung (Niri) ──────────────
  programs.niri = {
    enable = true;
    package = pkgs.niri; 
  };
  
  security.polkit.enable = true;
  programs.dconf.enable = true;
  services.xserver.xkb.layout = "de";

  # ────────────── Login Manager (greetd + nwg-hello) ──────────────
  # Expliziten Greeter-User anlegen, um Berechtigungs- und Cache-Probleme zu vermeiden
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    home = "/var/lib/greeter";
    createHome = true;
  };
  users.groups.greeter = {};

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.writeShellScript "nwg-hello-wrapper" ''
          # Cache-Datei erstellen falls sie nicht existiert
          mkdir -p /var/cache/nwg-hello
          if [ ! -f /var/cache/nwg-hello/cache.json ]; then
            echo '{}' > /var/cache/nwg-hello/cache.json
          fi
          
          # nwg-hello starten
          exec ${pkgs.nwg-hello}/bin/nwg-hello
        ''}";
        user = "greeter";
      };
    };
  };

  # Cache-Verzeichnis für nwg-hello erstellen (sowohl im System als auch im greeter Home)
  systemd.tmpfiles.rules = [
    "d /var/cache/nwg-hello 0755 greeter greeter -"
    "d /var/lib/greeter/.cache 0755 greeter greeter -"
    "d /var/lib/greeter/.cache/nwg-hello 0755 greeter greeter -"
    "d /var/lib/greeter/.local 0755 greeter greeter -"
    "d /var/lib/greeter/.local/share 0755 greeter greeter -"
    "d /var/lib/greeter/.config 0755 greeter greeter -"
    "d /var/lib/greeter/.config/nwg-hello 0755 greeter greeter -"
  ];

  i18n.extraLocaleSettings = {
    LC_TIME = "de_DE.UTF-8";
  };

  # ────────────── Portale (Screenshots & Fenster-Sharing) ──────────────
  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gnome 
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "gnome" ];
        "org.freedesktop.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.portal.ScreenCast" = [ "gnome" ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    bibata-cursors
    gnome-themes-extra
    xwayland 
    xwayland-satellite
    nwg-hello
    gtk3
    adwaita-icon-theme
  ];

  # ────────────── Schriftarten ──────────────
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
  ];
}
