{
  description = "Mortiferus-PC NixOS Ultimate Config";

  inputs = {
    # Ein verifizierter Commit von nixos-unstable (ca. 2 Tage alt)
    nixpkgs.url = "github:nixos/nixpkgs/ae294f930830540344e02b3971c3098567e41188";
    
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Home‑Manager einbinden
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Deine zusätzlichen Inputs
    noctalia-shell.url = "github:noctalia-dev/noctalia-shell";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    }; 
  };

  outputs = { self, nixpkgs, home-manager, disko, nixvim, ... }@inputs: 
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations."Mortiferus-PC" = nixpkgs.lib.nixosSystem {
        inherit system;

        # Inputs an alle Module weitergeben
        specialArgs = { inherit self inputs; };

        modules = [
          disko.nixosModules.disko
          ./configuration.nix
          nixvim.nixosModules.nixvim

          # Home‑Manager als NixOS‑Modul aktivieren
          home-manager.nixosModules.home-manager

          # Home‑Manager soll NixOS-Pakete nutzen
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };
}
