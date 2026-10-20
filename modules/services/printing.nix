{ config, pkgs, lib, ... }:

{
  services.printing.enable = true;

  hardware.sane = {
     enable = true;
     extraBackends = [ pkgs.sane-airscan ];
  };

  # hardware.sane setzt global LD_LIBRARY_PATH=/etc/sane-libs, was die
  # vorgebauten NVIDIA-Binaries (nvidia-smi, nvidia-offload) per SIGSEGV
  # abstuerzen laesst. Global leeren; die Scanner-CLI bekommt den Pfad
  # ueber einen Wrapper.
  environment.sessionVariables.LD_LIBRARY_PATH = lib.mkForce [];

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "scanimage" ''
      export LD_LIBRARY_PATH="/etc/sane-libs''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec ${pkgs.sane-backends}/bin/scanimage "$@"
    '')
  ];
}
