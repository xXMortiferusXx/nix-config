{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  boot.tmp.cleanOnBoot = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    max-jobs = "auto";
    cores = 0;
    min-free = 1073741824;
    max-free = 5368709120;
    trusted-substituters = [
      "https://noctalia.cachix.org"
      "https://umbriel.cachix.org"
    ];
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
      "https://umbriel.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "umbriel.cachix.org-1:JfNq/2yg2S6D6z4Z2dVSZrZlDPQTKtexB6GAVLD98nw="
    ];
  };

  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "75%";
  };
}
