{ pkgs, ... }:

let
  clipboard-sync = pkgs.rustPlatform.buildRustPackage rec {
    pname = "clipboard-sync";
    version = "0.2.0";

    src = pkgs.fetchCrate {
      inherit pname version;
      sha256 = "sha256-jwJqEHWYfPYkWzoFSFfhiAH/AVckP5k1qPbwnG60+dA=";
    };

    cargoHash = "sha256-kc+650Lk8hueAzxZGa/deWsNAWgsXCq+rz73BCQiS9E=";

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.libxcb ];

    doCheck = false;
  };
in
{
  environment.systemPackages = with pkgs; [
    wl-clipboard
    cliphist
    clipboard-sync
  ];

  # Clipboard-Sync Service für X11/Wayland Synchronisation (löst PoE2 Probleme)
  systemd.user.services.clipboard-sync = {
    description = "Synchronize clipboards between X11 and Wayland";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${clipboard-sync}/bin/clipboard-sync";
      Restart = "always";
      RestartSec = 3;
    };
  };

  # Clipboard Historie für Text
  systemd.user.services.cliphist = {
    description = "Clipboard history service (text)";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store'";
      Restart = "always";
      RestartSec = 3;
    };
  };

  # Clipboard Historie für Bilder
  systemd.user.services.cliphist-images = {
    description = "Clipboard history service (images)";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store'";
      Restart = "always";
      RestartSec = 3;
    };
  };
}
