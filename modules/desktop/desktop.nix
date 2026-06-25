{ config, pkgs, lib, ... }:

{
  security.polkit.enable = true;

  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.noctalia.greeter.apply-appearance" &&
          subject.user == "mortiferus")
      {
        return polkit.Result.YES;
      }
    });
  '';
  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.xfconf.enable = true;
  services.tumbler.enable = true;
  #services.gnome.tinysparql.enable = true;
  #services.gnome.localsearch.enable = true;
  programs.xwayland.enable = true;

  # localsearch/tracker3 braucht XDG_SESSION_CLASS=user
  #systemd.user.sessionVariables = {
  #  XDG_SESSION_CLASS = "user";
  #};

  ##### Für eventuelle Packete die noch fehlen ###### 
  environment.systemPackages = with pkgs; [
  cifs-utils
  samba
  gvfs

  # Fehlende Emblem-Icons für Nautilus bereitstellen
  (pkgs.stdenvNoCC.mkDerivation {
    name = "nautilus-emblem-unwritable";
    buildInputs = [ pkgs.adwaita-icon-theme ];
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/share/icons/hicolor/symbolic/emblems
      mkdir -p $out/share/icons/hicolor/16x16/emblems
      cp "${pkgs.adwaita-icon-theme}/share/icons/Adwaita/symbolic/legacy/emblem-important-symbolic.svg" \
        $out/share/icons/hicolor/symbolic/emblems/emblem-unwritable-symbolic.svg
      cp "${pkgs.adwaita-icon-theme}/share/icons/Adwaita/16x16/emblems/emblem-readonly.png" \
        $out/share/icons/hicolor/16x16/emblems/emblem-unwritable.png
    '';
  })
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    corefonts
  ];
}
