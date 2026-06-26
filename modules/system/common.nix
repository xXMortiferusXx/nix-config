# Zentraler Modul-Aggregator – importiert alle shared Module
# Von hosts/*/configuration.nix via `../modules/system/common.nix` eingebunden
{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.noctalia.nixosModules.default
    inputs.noctalia-greeter.nixosModules.default
    ./locale.nix
    ./networking.nix
    ./security.nix
    ./nix-settings.nix
    ./nix-ld.nix
    ../programs/zen-policies.nix
    ../hardware/audio.nix
    ../services/printing.nix
    ../services/noctalia.nix
    ../programs/shell.nix
    ../programs/editor.nix
    ../programs/fastfetch.nix
    ../programs/terminal.nix
    ../programs/tools.nix
    ../desktop/desktop.nix
    ../desktop/polkit.nix
    ../desktop/fonts.nix
    ../desktop/nautilus-emblems.nix
    ../desktop/noctalia-greeter.nix
    ../desktop/niri.nix
#    ../desktop/plasma.nix
    ../desktop/hyprland.nix
    ../desktop/quiet-sessions.nix
  ];
}
