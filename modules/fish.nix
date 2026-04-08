{ config, pkgs, lib, ... }:

{
  programs.fish = {
    enable = true;
    
    # Der interaktive Teil (wird bei jedem Start ausgeführt)
    interactiveShellInit = ''
      # Schaltet die Standard-Begrüßung von Fish aus
      set -g fish_greeting ""

      # Starte Fastfetch (wie du es in deiner alten config.fish hattest)
      ${pkgs.fastfetch}/bin/fastfetch

      # Initialisiert Zoxide (das smarte 'cd')
      ${pkgs.zoxide}/bin/zoxide init fish | source

      # CachyOS-Style Farben für die Syntax-Hervorhebung
      set -g fish_color_command green --bold
      set -g fish_color_param cyan
      set -g fish_color_autosuggestion 555
    '';

    # Hier nutzen wir shellAliases für echte Befehlsersetzungen
    # Wir nutzen lib.mkForce, um Konflikte mit der alias.nix zu vermeiden
    shellAliases = {
      # Der CachyOS/Modern-Look für Verzeichnisse
      ls = "eza --icons --group-directories-first";
      ll = lib.mkForce "eza -lha --icons --group-directories-first";
      tree = "eza --tree --icons";

      # Sicherheit & Navigation
      ".."    = "cd ..";
      "..."   = "cd ../..";
      "...."  = "cd ../../..";
      "grep"  = "grep --color=auto";
      "cat"   = "bat";
      
      # Deine bestehenden Aliase (hier zentralisiert)
      "nix-search" = lib.mkForce "nix search nixpkgs";
      "fetch"      = "fastfetch";
    };

    # Abkürzungen (Tippe den Buchstaben + Leertaste zum Erweitern)
    shellAbbrs = {
      n  = "nix";
      ns = "nix-env -qaP";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
    };
  };

  # Der moderne Starship-Prompt (CachyOS-Style)
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

  # Pakete, die Fish für diese Features benötigt
  environment.systemPackages = with pkgs; [
    eza      # ls-Ersatz mit Icons
    zoxide   # Schneller Verzeichniswechsel (z statt cd)
    bat      # cat-Ersatz mit Syntax-Highlighting
    fzf      # Fuzzy Finder für die History-Suche (Strg+R)
    starship # Der schicke Prompt
    fastfetch # System-Informationen
  ];
}
