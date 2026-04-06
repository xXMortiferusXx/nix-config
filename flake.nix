{
  description = "Mortiferus-PC NixOS Ultimate Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # JETZT RICHTIG: Laut deiner Quelle
    noctalia-shell.url = "github:noctalia-dev/noctalia-shell"; 
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs = { self, nixpkgs, ... }@inputs: 
    let
      system = "x86_64-linux";
    in {
    nixosConfigurations."Mortiferus-PC" = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [ ./configuration.nix ];
    };
  };
}
