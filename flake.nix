{
  description = "Mortiferus-PC NixOS Ultimate Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home‑Manager einbinden
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Deine zusätzlichen Inputs
    noctalia-shell.url = "github:noctalia-dev/noctalia-shell";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    nix-gaming.url = "github:fufexan/nix-gaming";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations."Mortiferus-PC" = nixpkgs.lib.nixosSystem {
        inherit system;

        # Inputs an alle Module weitergeben
        specialArgs = { inherit inputs; };

        modules = [
          ./configuration.nix

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

