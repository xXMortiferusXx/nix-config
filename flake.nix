# Mortiferus NixOS-Flake (Hosts: nex, lion-pc, benny, styx, test).
{
  description = "Mortiferus NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # lsfg-vk: Quelle git.lsfg-vk.dev (master), flake=false -> Selbstbau
    lsfg-vk-src.url = "git+https://git.lsfg-vk.dev/lsfg-vk.git?ref=master";
    lsfg-vk-src.flake = false;

    # Umbriel direkt vom Repo (nixpkgs pinnt zu alt); git+https wegen Submodule scenefx
    umbriel = {
      url = "git+https://github.com/noctalia-dev/umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # CachyOS-Kernel, folgt master; Binär-Cache: attic.xuyh0120.win/lantian
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel";
    };

    # Arctis Sound Manager (eigener Fork; nur benny, nex nutzt den GC7)
    arctis-sound-manager = {
      url = "github:xXMortiferusXx/Arctis-Sound-Manager?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # BedrockOnLinux: Minecraft Bedrock via WineGDK (nur lion-pc)
    bedrock-on-linux = {
      url = "github:Wyze3306/BedrockOnLinux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, home-manager, arctis-sound-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      specialArgs = { inherit self inputs; };

      # Disko-Configs fuer den Installer (--argstr device); Default nur fuer Rebuild.
      diskoConfigurations.nex = { device ? "/dev/nvme0n1", ... }:
        import ./hosts/nex/disk-config.nix { inherit device; };
      diskoConfigurations.styx = { device ? "/dev/nvme0n1", ... }:
        import ./modules/system/disko-basic.nix { inherit device; };
      diskoConfigurations.test = { device ? "/dev/nvme0n1", ... }:
        import ./hosts/test/disk-config.nix { inherit device; };
      diskoConfigurations.lion-pc = { device ? "/dev/nvme0n1", ... }:
        import ./hosts/lion-pc/disk-config.nix { inherit device; };
      # benny: SATA-Datentraeger -> Default /dev/sda
      diskoConfigurations.benny = { device ? "/dev/sda", ... }:
        import ./hosts/benny/disk-config.nix { inherit device; };
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

      # Minimaler Test-Host (QEMU, Installer-Tests)
      nixosConfigurations."test" = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          disko.nixosModules.disko
          ./hosts/test/configuration.nix
        ];
      };

      # lion-pc: AMD CPU + Radeon RX 580
      nixosConfigurations."lion-pc" = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          disko.nixosModules.disko
          ./hosts/lion-pc/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

      # benny: Intel i5 (Ivy Bridge) + HD 4000
      nixosConfigurations."benny" = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          disko.nixosModules.disko
          arctis-sound-manager.nixosModules.default
          ./hosts/benny/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

      # Installer-ISO fuer QEMU-Tests
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
