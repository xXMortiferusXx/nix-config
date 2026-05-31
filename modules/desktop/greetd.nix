{ config, pkgs, lib, ... }:

let
  # nwg-hello JSON Config – nur Niri und Hyprland als Sessions
  nwgHelloConfig = pkgs.writeText "nwg-hello.json" (builtins.toJSON {
    session_dirs = [];
    custom_sessions = [
      { name = "Niri";     exec = "niri --session 2>/dev/null"; }
      { name = "Hyprland"; exec = "Hyprland";     }
#      { name = "KDE Plasma"; exec = "startplasma-wayland"; }
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

  # labwc autostart – startet nwg-hello mit expliziten Config-Pfaden
  labwcAutostart = pkgs.writeShellScript "labwc-autostart" ''
    ${pkgs.nwg-hello}/bin/nwg-hello \
        -c /etc/nwg-hello/nwg-hello.json \
        -s /etc/nwg-hello/nwg-hello.css \
        2>/dev/null
    ${pkgs.labwc}/bin/labwc --exit 2>/dev/null
  '';

  # labwc Config – minimal, nur für den Greeter
  labwcConfigDir = pkgs.writeTextDir "rc.xml" ''
    <?xml version="1.0"?>
    <labwc_config>
      <keyboard>
        <default/>
      </keyboard>
        <theme><cursor>Bibata-Modern-Ice</cursor></theme> 
    </labwc_config>
  '';

in
{
  # SDDM deaktivieren
  services.displayManager.sddm.enable = lib.mkForce false;
  services.xserver.enable = lib.mkForce false;

  # greetd mit labwc als Compositor
  services.greetd = {
    enable = true;
    settings = {
      terminal.vt = lib.mkForce 3;
      default_session = {
        command = "${pkgs.coreutils}/bin/env XCURSOR_THEME=Bibata-Modern-Ice XCURSOR_SIZE=24 ${pkgs.labwc}/bin/labwc -C ${labwcConfigDir} -s ${labwcAutostart} 2>/dev/null";
        user = "greeter";
      };
    };
  };

  # greeter User anlegen
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    packages = [ pkgs.bibata-cursors pkgs.adwaita-icon-theme pkgs.papirus-icon-theme ];
    extraGroups = [ "video" "input" ];
  };
  users.groups.greeter = {};

  # Cache für nwg-hello (letzte Session merken)
  systemd.tmpfiles.settings."10-nwg-hello" = {
    "/var/cache/nwg-hello".d = {
      mode = "0755";
      user = "greeter";
      group = "greeter";
    };
  };

  # nwg-hello JSON Config
  environment.etc."nwg-hello/nwg-hello.json".source = nwgHelloConfig;

  # Wallpaper – relativer Pfad zur greetd.nix anpassen
  environment.etc."nwg-hello/background.jpg".source =
    ../../home/mortiferus/config/niri/login.jpg;

  # CSS mit Hintergrundbild und lesbarer Schrift
  environment.etc."nwg-hello/nwg-hello.css".text = ''
  * {
    font-family: "Noto Sans", monospace;
    font-size: 14px;
    color: #ffffff;
  }
  window {
    background-image: url("/etc/nwg-hello/background.jpg");
    background-size: cover;
    background-position: center;
  }
  #form-wrapper {
    background-color: rgba(0, 0, 0, 0.4);
    border-radius: 12px;
    padding: 20px;
  }
  button {
    background: rgba(255, 255, 255, 0.1) none;
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: 18px;
    padding: 12px;
    color: #ffffff;
  }
  button:hover {
    background: rgba(255, 255, 255, 0.2) none;
    border: 1px solid rgba(255, 255, 255, 0.6);
  }
  entry {
    background-color: rgba(255, 255, 255, 0.15);
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: 18px;
    padding: 12px;
    color: #ffffff;
    caret-color: #ffffff;
  }
  
  /* ─── COMBOBOX BUTTON (Das geschlossene Dropdown) ─── */
  combobox button {
    background: rgba(255, 255, 255, 0.1) none;
    color: #ffffff;
    border-radius: 18px;
    border: 1px solid rgba(255, 255, 255, 0.3);
  }
  combobox button:hover {
    background: rgba(255, 255, 255, 0.2) none;
    border: 1px solid rgba(255, 255, 255, 0.6);
  }

  /* ─── DROPDOWN LISTE (Das geöffnete Menü) ─── */
  /* Das sorgt dafür, dass die aufklappende Liste dunkel und lesbar ist */
  combobox window, 
  combobox popover, 
  combobox menu {
    background-color: #1a232a; /* Ein edles, sehr dunkles Blau/Grau */
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 12px;
    padding: 6px;
  }

  /* Textfarbe der nicht ausgewählten Einträge in der Liste */
  combobox cellview,
  combobox row,
  combobox * {
    color: rgba(255, 255, 255, 0.8);
  }

  /* ─── SELEKTIERTER EINTRAG (Hover / Ausgewählt) ─── */
  /* Nutzt deinen Niri-Farbakzent (#7aa89f) für die Auswahl */
  combobox *:selected,
  combobox row:selected,
  row:selected,
  combobox item:hover {
    background-color: #7aa89f; /* Deine aktive Niri focus-ring Farbe */
    color: #111111;            /* Dunkler Text auf hellem Grün für perfekten Kontrast */
    border-radius: 8px;
  }
  '';

  environment.systemPackages = with pkgs; [
    
    nwg-hello
    labwc
  ];

  # PAM für greetd
  security.pam.services.greetd.enableGnomeKeyring = true;
}
