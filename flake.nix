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

    # lsfg-vk (neue Quelle: git.lsfg-vk.dev statt GitHub; master = laufende Entwicklung)
    lsfg-vk-src.url = "git+https://git.lsfg-vk.dev/lsfg-vk.git?ref=master";
    lsfg-vk-src.flake = false;

    # Noctalia Greeter (ohne follows für Cachix)
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
    };

    # Umbriel Compositor – direkt vom Repo statt nixpkgs, damit Fixes zeitnah
    # ankommen (nixpkgs pinnt oft lange alte Revs). git+https statt github:,
    # weil das Repo das Submodule subprojects/scenefx braucht.
    umbriel = {
      url = "git+https://github.com/noctalia-dev/umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # xddxdd/nix-cachyos-kernel (CachyOS Kernel für NixOS)
    # - Binary Cache: https://attic.xuyh0120.win/lantian
    # - Overlay: inputs.nix-cachyos-kernel.overlays.pinned
    # - Packages: pkgs.cachyosKernels.linuxPackages-cachyos-latest
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };

    # Arctis Sound Manager (SteelSeries GG/Sonar-Ersatz für Linux)
    # - Modul: inputs.arctis-sound-manager.nixosModules.default
    # - Option: services.arctis-sound-manager.enable
    arctis-sound-manager = {
      url = "github:loteran/Arctis-Sound-Manager?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  
  outputs = { self, nixpkgs, disko, home-manager, zen-browser, noctalia-greeter, arctis-sound-manager, ... }@inputs:
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
          arctis-sound-manager.nixosModules.default
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
