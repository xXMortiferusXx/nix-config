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

    # lsfg-vk (neue Quelle: git.lsfg-vk.dev statt GitHub; master = laufende Entwicklung)
    lsfg-vk-src.url = "git+https://git.lsfg-vk.dev/lsfg-vk.git?ref=master";
    lsfg-vk-src.flake = false;

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
    # Keine Branch-Pin: folgt dem Default-Branch (master, Auto-Update).
    # Kernel-Stand über flake.lock gepinnt; Update: nix flake update nix-cachyos-kernel
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel";
    };

    # Arctis Sound Manager (SteelSeries GG/Sonar-Ersatz für Linux)
    # - Modul: inputs.arctis-sound-manager.nixosModules.default
    # - Option: services.arctis-sound-manager.enable
    # Quelle: eigener Fork (xXMortiferusXx) statt upstream (loteran), weil dort
    # der 8ch-7.1-Loopback-Fix (Game/Media/Aux → HeSuVi) entwickelt wird.
    # Aktuell nur auf benny (Headset) — nex läuft über den Sound Blaster GC7.
    arctis-sound-manager = {
      url = "github:xXMortiferusXx/Arctis-Sound-Manager?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  
  outputs = { self, nixpkgs, disko, home-manager, arctis-sound-manager, ... }@inputs:
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
      diskoConfigurations.lion-pc = { device ? "/dev/nvme0n1", ... }:
        import ./hosts/lion-pc/disk-config.nix { inherit device; };
      # benny: SATA-Datentraeger (2013er-Rechner) -> Default /dev/sda
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

      # Test-Host: minimal fuer Installer-Testing (QEMU-VM)
      nixosConfigurations."test" = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          disko.nixosModules.disko
          ./hosts/test/configuration.nix
        ];
      };

      # lion-pc: Gaming-PC fuer lion (AMD CPU + Radeon RX 580), Umbriel-DE,
      # Flatpak-Bazaar fuer eigenstaendige Roblox-Installation (Sober/Vinegar)
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

      # benny: Intel CPU + AMD Radeon R9 280 (GCN 1.0).
      # Sonderfall GPU: 6.18-LTS-Kernel + amdgpu-SI/CIK-Params -> Vulkan/RADV
      # (siehe modules/system/boot-benny.nix). Sobald neue GPU: Kernel umstellen.
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
