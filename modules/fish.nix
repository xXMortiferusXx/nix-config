{ config, pkgs, lib, ... }:

{
  programs.fish = {
    enable = true;
    
    interactiveShellInit = ''
      # Schaltet die Standard-Begrüßung von Fish aus
      set -g fish_greeting ""

      # Starte Fastfetch
      ${pkgs.fastfetch}/bin/fastfetch

      # Initialisiert Zoxide
      ${pkgs.zoxide}/bin/zoxide init fish | source

      # CachyOS-Style Farben
      set -g fish_color_command green --bold
      set -g fish_color_param cyan
      set -g fish_color_autosuggestion 555
    '';

    shellAliases = {
      ls       = "eza --icons --group-directories-first";
      # mkForce nicht nötig, da ll nirgendwo sonst definiert ist
      ll       = "eza -lha --icons --group-directories-first";
      tree     = "eza --tree --icons";
      ideamaker = "QT_QPA_PLATFORM=xcb LD_LIBRARY_PATH=\"\" ~/Apps/ideaMaker.AppImage";
      ".."     = "cd ..";
      "..."    = "cd ../..";
      "...."   = "cd ../../..";
      "grep"   = "grep --color=auto";
      "cat"    = "bat";
      # mkForce nicht nötig, da nix-search nirgendwo sonst definiert ist
      "nix-search" = "nix search nixpkgs";
      "fetch"      = "fastfetch";
    };

    shellAbbrs = {
      n  = "nix";
      ns = "nix-env -qaP";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$python$character";
      directory.style = "bold blue";
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    eza
    zoxide
    bat
    fzf
    starship
    fastfetch
  ];
}
