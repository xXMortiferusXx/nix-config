# Benutzer lion (lion-pc – Gaming-PC)
# Groups: networkmanager, wheel, video, audio, greeter
# Kein openrazer/scanner/lp (kein Razer, kein Scanner/Printer auf lion-pc)
{ config, pkgs, inputs, ... }:
{
  users.users.lion = {
    isNormalUser = true;
    description = "Lion";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "greeter" ];
    shell = pkgs.fish;

    packages = with pkgs; [
      # Browser (Flake-Integration) — gleiche Basis wie nex/styx
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}