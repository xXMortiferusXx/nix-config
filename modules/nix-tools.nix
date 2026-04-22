{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fzf
    jq
    wl-clipboard
  ];

  programs.fish.interactiveShellInit = ''
    function nsearch
        set query (if test (count $argv) -gt 0; echo $argv[1]; else; echo "."; end)
        nix search nixpkgs# $query --json 2>/dev/null | \
          jq -r 'to_entries[] | "\(.key)\t\(.value.version // "unbekannt")\t\(.value.description // "keine Beschreibung")" | gsub("\n"; " ")' | \
          fzf --delimiter '\t' \
              --with-nth 1,2 \
              --preview 'echo {} | cut -f3' \
              --preview-window 'right:40%' \
              --bind 'ctrl-y:execute(echo {} | cut -f1 | wl-copy)' \
              --header 'STRG+Y: Paketname kopieren | ESC: Abbrechen'
    end
  '';
}
