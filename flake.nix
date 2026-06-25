{
  description = "Mortiferus NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-small.url = "github:nixos/nixpkgs/nixos-unstable-small";
    
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Home-Manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Deine zusätzlichen Inputs
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    hyprland.url = "github:hyprwm/Hyprland";

    # lsfg-vk GitHub-Version (automatisch develop branch)
    lsfg-vk-src.url = "github:PancakeTAS/lsfg-vk/develop";
    lsfg-vk-src.flake = false;

    # Noctalia v5 (ohne follows für Cachix-Binary-Cache)
    noctalia = {
      url = "github:noctalia-dev/noctalia";
    };

    # Noctalia Greeter (ohne follows für Cachix)
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
    };

  };
  
  outputs = { self, nixpkgs, nixpkgs-small, disko, home-manager, noctalia, noctalia-greeter, ... }@inputs:
    let
      system = "x86_64-linux";
      specialArgs = { inherit self inputs; };
    in
    {
      nixosConfigurations."nex" = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          disko.nixosModules.disko
          ./hosts/nex/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
          {
            _module.args.smallPkgs = import nixpkgs-small {
              inherit system;
              config.allowUnfree = true;
            };
          }
        ];
      };

      nixosConfigurations."styx" = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          disko.nixosModules.disko
          ./hosts/styx/configuration.nix
          #./modules/home/backbone.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
}
