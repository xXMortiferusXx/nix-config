# Fastfetch mit custom JSON-Konfig (Hardware/Software/Netzwerk/Zeit)
# Wird bei jeder Fish-Shell gestartet
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [ fastfetch ];

  environment.etc."fastfetch/config.jsonc".text = ''
    {
      "logo": "NixOS",
      "display": {
        "separator": " ",
        "constants": [
          "\u001b[38;2;81;188;254m\u001B[1m",
          "\u001b[38;2;105;181;254m\u001B[1m",
          "\u001b[38;2;130;173;253m\u001B[1m",
          "\u001b[38;2;154;166;253m\u001B[1m",
          "\u001b[38;2;169;160;253m\u001B[1m",
          "\u001b[38;2;179;154;253m\u001B[1m",
          "\u001b[38;2;186;153;253m\u001B[1m",
          "\u001b[38;2;192;163;253m\u001B[1m",
          "\u001b[38;2;198;167;253m\u001B[1m",
          "\u001b[38;2;205;173;252m\u001B[1m",
          "┌──────",
          "───────",
          "──────┐"
         ],
        "percent": {
          "type": 9,
          "color": {
            "green": "#51bcfe",
            "yellow": "#abff4a",
            "red": "#ff8f45"
          }
        }
      },
      "modules": [
        "break",
        {
          "type": "title",
          "key": "{$4}                󱐋󱐋 "
        },
        {
          "type": "custom",
          "format": "{$1}{$11}{$2}{$12}{$3}{$12}{$4}{$12}{$5}{$12} Hardware {$6}{$12}{$7}{$12}{$8}{$12}{$9}{$12}{$10}{$13}"
        },
        {
          "type": "host",
          "key": "{$1}├   PC        "
        },
        {
          "type": "board",
          "key": "{$2}├ 󱔼  Board     "
        },
        {
          "type": "cpu",
          "key": "{$3}├   CPU       "
        },
        {
          "type": "gpu",
          "key": "{$4}├ 󰾲  GPU       "
        },
        {
          "type": "display",
          "key": "{$5}├ 󰍹  Display   "
        },
        {
          "type": "sound",
          "key": "{$6}├ 󰓃  Sound     "
        },
        {
          "type": "battery",
          "key": "{$6}├ 󰢟  Battery   ",
          "format": "{manufacturer} {model-name} ({capacity})"
        },
        {
          "type": "memory",
          "key": "{$7}├   Memory    ",
          "percent": {
            "type": 3,
            "green": 30,
            "yellow": 70
          }
        },
        {
          "type": "swap",
          "key": "{$8}├ 󰯍  Swap      ",
          "percent": {
            "type": 3,
            "green": 30,
            "yellow": 70
          }
        },
        {
          "type": "disk",
          "key": "{$9}├   NixOS     ",
          "folders": ["/"],
          "percent": {
            "type": 3,
            "green": 30,
            "yellow": 70
          }
        },
        {
          "type": "disk",
          "key": "{$10}└   Gaming    ",
          "folders": ["/gaming"],
          "percent": {
            "type": 3,
            "green": 30,
            "yellow": 70
          }
        },
        {
          "type": "custom",
          "format": "{$1}{$11}{$2}{$12}{$3}{$12}{$4}{$12}{$5}{$12} Software {$6}{$12}{$7}{$12}{$8}{$12}{$9}{$12}{$10}{$13}"
        },
        {
          "type": "os",
          "key": "{$10}├   Distro    ",
          "format": "{name} {build-id} ({codename}) {arch}"
        },
        {
          "type": "kernel",
          "key": "{$10}├   Kernel    "
        },
        {
          "type": "bios",
          "key": "{$9}├ 󰚗  BIOS      "
        },
        {
          "type": "packages",
          "key": "{$9}├ 󰏖  Packages  "
        },
        {
          "type": "Processes",
          "key": "{$9}├ 󰑮  Processes "
        },
        {
          "type": "shell",
          "key": "{$8}├   Shell     "
        },
        {
          "type": "terminal",
          "key": "{$7}├   Terminal  "
        },
        {
          "type": "terminalfont",
          "key": "{$6}├ 󰛖  Term Font "
        },
        {
          "type": "de",
          "key": "{$5}├   DE        "
        },
        {
          "type": "lm",
          "key": "{$4}├ 󰧨  Login     "
        },
        {
          "type": "wm",
          "key": "{$3}├   Window    "
        },
        {
          "type": "wmtheme",
          "key": "{$2}├ 󰉼  Theme     "
        },
        {
          "type": "font",
          "key": "{$2}├ 󰛖  Font      "
        },
        {
          "type": "opengl",
          "key": "{$1}├ 󰆧  OpenGL    "
        },
        {
          "type": "vulkan",
          "key": "{$1}└ 󰈸  Vulkan    "
        },
        {
          "type": "custom",
          "format": "{$1}{$11}{$2}{$12}{$3}{$12}{$4}{$12}{$5}{$12}Verbindung{$6}{$12}{$7}{$12}{$8}{$12}{$9}{$12}{$10}{$13}"
        },
        {
          "type": "bluetooth",
          "key": "{$1}├ 󰂱  Bluetooth ",
          "format": "{1} - {4}"
        },
        {
          "type": "bluetoothradio",
          "key": "{$1}├ 󰂯  BT Radio  ",
          "format": "{5}"
        },
        {
          "type": "wifi",
          "key": "{$2}├   WiFi      ",
          "format": "{4} - {7} - {13} GHz - {10}",
          "showErrors": "never"
        },
        {
          "type": "dns",
          "key": "{$4}├ 󱦂  DNS       "
        },
        {
          "type": "localip",
          "key": "{$6}├ 󰩟  Local IP  ",
          "format": "{1} - {3}",
          "showMac": true
        },
        {
          "type": "publicip",
          "key": "{$8}└ 󰩠  Public IP ",
          "format": "{1} - {2}"
        },
        {
          "type": "custom",
          "format": "{$1}{$11}{$2}{$12}{$3}{$12}{$4}{$12}{$5}{$12}   Zeit   {$6}{$12}{$7}{$12}{$8}{$12}{$9}{$12}{$10}{$13}"
        },
        {
          "type": "DateTime",
          "key": "{$10}├ 󰥔  Date/Time "
        },
        {
          "key": "{$8}├   OS Age    ",
          "type": "disk",
          "folders": "/",
          "format": "{create-time:10} ({days} days)"
        },
        {
          "type": "uptime",
          "key": "{$6}└   Uptime    "
        },
        {
          "type": "custom",
          "format": "                {$10}❄ {$9}❄ {$8}❄ {$7}❄ {$6}❄ {$5}❄ {$4}❄ {$3}❄ {$2}❄ {$1}❄"
        }
      ]
    }
  '';

  programs.fish.interactiveShellInit = ''
    ${pkgs.fastfetch}/bin/fastfetch --config /etc/fastfetch/config.jsonc
  '';
}
