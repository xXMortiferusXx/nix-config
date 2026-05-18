{ config, pkgs, lib, ... }:

let
  # nwg-hello Config - EXAKT wie in deinem Backup, nur custom_sessions ergänzt
  nwgHelloConfig = pkgs.writeText "nwg-hello.json" (builtins.toJSON {
    session_dirs = []; 
    custom_sessions = [
      {
        name = "Niri";
        exec = "niri-session";
      }
      {
        name = "Hyprland";
        exec = "Hyprland";
      }
    ];
    monitor_nums = [];
    form_on_monitors = [];
    delay_secs = 1;
    cmd-sleep = "systemctl suspend";
    cmd-reboot = "systemctl reboot";
    cmd-poweroff = "systemctl poweroff";
    gtk-theme = "Adwaita-dark";
    gtk-icon-theme = "Papirus-Dark";
    gtk-cursor-theme = "Bibata-Modern-Ice";
    prefer-dark-theme = true;
    template-name = "";
    time-format = "%H:%M:%S";
    date-format = "%A, %d. %B %Y";
  });

  # labwc autostart – EXAKT wie im Backup
  labwcAutostart = pkgs.writeShellScript "labwc-autostart" ''
    ${pkgs.nwg-hello}/bin/nwg-hello
  '';

  # labwc Config – Jetzt mit dem Cursor-Eintrag
  labwcConfigDir = pkgs.writeTextDir "rc.xml" ''
    <?xml version="1.0"?>
    <labwc_config>
      <keyboard>
        <default/>
      </keyboard>
      <theme>
        <cursor>Bibata-Modern-Ice</cursor>
      </theme>
    </labwc_config>
  '';

in
{
  services.displayManager.sddm.enable = lib.mkForce false;
  services.xserver.enable = lib.mkForce false;

  services.greetd = {
    enable = true;
    settings = {
      terminal.vt = 1;
      default_session = {
        # Wir fügen hier nur env für den Cursor hinzu, der Rest bleibt Backup-Style
        command = "${pkgs.coreutils}/bin/env XCURSOR_THEME=Bibata-Modern-Ice XCURSOR_SIZE=24 ${pkgs.labwc}/bin/labwc -C ${labwcConfigDir} -s ${labwcAutostart}";
        user = "greeter";
      };
    };
  };

  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    extraGroups = [ "video" "input" ];
    # Der Greeter braucht die Icons physisch in seinem Pfad
    packages = [ 
      pkgs.bibata-cursors 
      pkgs.adwaita-icon-theme
      pkgs.papirus-icon-theme
    ];
  };
  users.groups.greeter = {};

  # Das hier war im Backup und bleibt drin für das Theme
  environment.pathsToLink = [
    "/share/wayland-sessions"
  ];

  # Verlinkungen für Config und Hintergrund
  environment.etc."nwg-hello/nwg-hello.json".source = nwgHelloConfig;
  environment.etc."nwg-hello/background.jpg".source = ../../home/mortiferus/config/niri/login.jpg;

  environment.systemPackages = with pkgs; [
    nwg-hello
    labwc
  ];

  security.pam.services.greetd.enableGnomeKeyring = true;
}
