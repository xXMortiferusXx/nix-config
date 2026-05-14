{ config, pkgs, lib, ... }:

{
  services.envfs.enable = false;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      dotnet-runtime_8
      stdenv.cc.cc
      zlib
      fuse2
      fuse3
      icu
      nspr
      nss
      openssl
      curl
      cups
      expat
      glib
      dbus
      libuuid
      libusb1
      libnghttp2
      libidn2
      libssh2
      libssh
      openldap
      libpsl
      libkrb5
      keyutils
      p11-kit
      libtasn1
      libGL
      libGLU
      mesa
      freetype
      fontconfig
      pango
      cairo
      atk
      gdk-pixbuf
      gtk3
      alsa-lib
      at-spi2-core
      libx11
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrender
      libxtst
      libxcomposite
      libxrandr
      libxinerama
      libsm
      libice
      libxcb
      libxshmfence
      libxkbcommon
      libxmu
      libxft
      libXt
      xcbutil
      xcbutilwm
      xcbutilimage
      xcbutilkeysyms
      xcbutilrenderutil
      xcbutilcursor
      gmp
      libmpc
      mpfr
      lz4
      zstd
      bzip2
      libgcrypt
      libgpg-error
      libxml2
      sqlite
      libunwind
      libelf
      e2fsprogs
      libxcrypt-legacy
      libtool
      libao
      libidn
      libunistring
      libedit
      libvdpau
      libva
      libdrm
      freeglut
      libtheora
      libogg
      libvorbis
      libvpx
      wayland
      gtk2
      util-linux
    ]
    ++ (pkgs.steam-run.args.multiPkgs pkgs);
  };

  environment.systemPackages = with pkgs; [
    xclip
    e2fsprogs
    libnotify
    openldap
    nix-tree
    gcc
    wget
    git
    htop
    pciutils
    usbutils
    mesa-demos
    ntfs3g
    unzip
    unrar
    p7zip
    hydra-check
    nvd
  ];

  environment.etc."zen/policies/policies.json".text = builtins.toJSON {
    policies = {
      Preferences = {
        "ui.context_menus.after_remote_menus" = {
          Value = true;
          Status = "locked";
        };
        "privacy.resistFingerprinting.letterboxing" = {
          Value = false;
          Status = "locked";
        };
        "zen.window-sync.enabled" = {
          Value = false;
          Status = "locked";
        };
      };
    };
  };
}
