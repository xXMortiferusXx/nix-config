# AppImage-Support via binfmt_misc – .AppImage-Dateien direkt ausführbar
# Der Kernel erkennt die Magische Zahl (\x7fELF...AI\x02) und routet automatisch durch appimage-run
{ config, lib, pkgs, ... }:

{
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [
        pkgs.libnghttp2
        pkgs.libidn2
        pkgs.libpsl
        pkgs.lz4
        pkgs.zstd
        pkgs.libtasn1
        pkgs.sqlite
        pkgs.icu # .NET/Avalonia-AppImages (z.B. Sidekick) erwarten ICU systemweit
        pkgs.xsel
        pkgs.webkitgtk_4_1
      ];
    };
  };
}