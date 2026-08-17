{
  description = "Mortiferus NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Home-Manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Deine zusätzlichen Inputs
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    # lsfg-vk GitHub-Version (automatisch develop branch)
    lsfg-vk-src.url = "github:PancakeTAS/lsfg-vk/develop";
    lsfg-vk-src.flake = false;

    # Noctalia v5 (cachix-Branch = letzter gecachter Commit)
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };

    # Noctalia Greeter (ohne follows für Cachix)
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
    };

    # Hyprland (offizieller Flake mit Binary Cache)
    # - Binary Cache: https://hyprland.cachix.org
    # - Paket: inputs.hyprland.packages.${system}.hyprland
    hyprland.url = "github:hyprwm/Hyprland";

    # sodiboo/niri-flake (Community-Flake mit Binary Cache)
    # - niri-stable / niri-unstable verfügbar
    # - Binary Cache: https://niri.cachix.org
    # - Overlay: inputs.niri.overlays.niri
    niri = {
      url = "github:sodiboo/niri-flake";
    };

  };
  
  outputs = { self, nixpkgs, disko, home-manager, zen-browser, noctalia, noctalia-greeter, ... }@inputs:
    let
      system = "x86_64-linux";
      specialArgs = { inherit self inputs; };

      # Disko-Configs fuer den Installer (--flake .#<host> --argstr device /dev/nvmeXn1)
      # device wird vom Installer per --argstr device uebergeben.
      # Default nur fuer normales Rebuild, wenn kein Device uebergeben wird.
      diskoConfigurations.nex = { device ? "/dev/nvme0n1", ... }:
        import ./hosts/nex/disk-config.nix { inherit device; };
      diskoConfigurations.styx = { device ? "/dev/nvme0n1", ... }:
        import ./modules/system/disko-basic.nix { inherit device; };
      diskoConfigurations.test = { device ? "/dev/nvme0n1", ... }:
        import ./hosts/test/disk-config.nix { inherit device; };
    in
    {
      inherit diskoConfigurations;

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
        ];
      };

      nixosConfigurations."styx" = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          disko.nixosModules.disko
          ./hosts/styx/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

      # Test-Host: minimal fuer Installer-Testing (QEMU-VM)
      nixosConfigurations."test" = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          disko.nixosModules.disko
          ./hosts/test/configuration.nix
        ];
      };

      # Installer ISO fuer QEMU-Testing
      packages.${system}.installer-iso = let
        iso = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ({ pkgs, ... }: {
              nix.settings.experimental-features = [ "nix-command" "flakes" ];
              environment.systemPackages = with pkgs; [ git curl wget vim parted ];
            })
          ];
        };
      in iso.config.system.build.isoImage;
    };
}
