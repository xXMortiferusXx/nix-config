# Gaming-Modul für lion-pc — gleiche Gaming-Stack wie nex, ABER:
# - ohne sunshine (Game-Streaming, nex-only)
# - Pakete für User lion statt mortiferus
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./steam.nix
    ./gamescope.nix
    ./scripts-lion.nix # lion-spezifisch: DDC/CI statt brightnessctl (externe Monitore)
    ./udev.nix
  ];

  users.users.lion.packages = with pkgs; [
    lutris
    heroic
    gamescope
    #umu-launcher
    protonplus

    # Minecraft Bedrock (Windows/GDK) fuer den Sohn.
    # Xbox-Freunde-Einladungen laufen IN-GAME (kein Xbox-App auf Linux):
    #   Play -> Worlds -> Stift neben der Welt -> Multiplayer an,
    #   Spieler auf "friends" -> ESC -> Social -> Invite to Play -> Send Invites.
    # Beide muessen denselben MS-Account gegenseitig als Xbox-Freund haben.
    # Kein Abo noetig, beide gleichzeitig online.
    inputs.bedrock-on-linux.packages."x86_64-linux".default
  ];
}