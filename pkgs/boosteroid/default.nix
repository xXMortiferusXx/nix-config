# Boosteroid Cloud-Gaming-Client (portables Upstream-Binary).
{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, copyDesktopItems
, makeDesktopItem
, addDriverRunpath
# Laufzeit-Libs (aus dem ELF NEEDED-Block ermittelt)
, alsa-lib
, dbus
, fontconfig
, freetype
, libGL
, libpulseaudio
, libva
, libvdpau
, libxkbcommon
, libxcb
, libX11
, libXi
, libXfixes
, numactl
, pcre2
, systemd
, wayland
, xcbutilwm
, xcbutilimage
, xcbutilkeysyms
, xcbutilrenderutil
, xz
, zlib
}:

let
  runtimeLibs = [
    alsa-lib
    dbus
    fontconfig
    freetype
    libGL
    libpulseaudio
    libva
    libvdpau
    libxkbcommon
    libxcb
    libX11
    libXi
    libXfixes
    numactl
    pcre2
    systemd
    wayland
    xcbutilwm
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    xz
    zlib
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "boosteroid";
  # Upstream liefert eine unversionierte Datei; Datum der Auslieferung als Version.
  version = "unstable-2026-09-30";

  src = fetchurl {
    url = "https://boosteroid.com/linux/installer/boosteroid_portable.tar";
    hash = "sha256-R4s3nA9YyaNovO04Dv9svq7Z/y9JyRLIFfL4TVFkjqo=";
    # Der Server antwortet ohne Browser-UA mit 403.
    curlOptsList = [ "-A" "Mozilla/5.0" ];
  };

  # Tar enthält genau eine selbstenthaltene Binary → kein Standard-unpackPhase.
  unpackPhase = ''
    runHook preUnpack
    tar xf $src
    runHook postUnpack
  '';

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
    addDriverRunpath # GPU-/VA-API-Treiberpfade (/run/opengl-driver) einbacken
  ];

  buildInputs = runtimeLibs;

  # Nur wirklich benötigte Libs patchen; optionale dlopen-Abhängigkeiten ignorieren.
  autoPatchelfIgnoreMissingDeps = true;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 Boosteroid $out/opt/boosteroid/Boosteroid
    # Launcher kopiert die Binary in ein beschreibbares Verzeichnis (Log/Config
    # landen sonst im read-only Store) und startet sie von dort.
    install -Dm755 ${./launcher.sh} $out/libexec/boosteroid
    makeWrapper $out/libexec/boosteroid $out/bin/boosteroid \
      --set BOOSTEROID_BIN "$out/opt/boosteroid/Boosteroid" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
      --prefix LIBVA_DRIVERS_PATH : "/run/opengl-driver/lib/dri"
    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "boosteroid";
      desktopName = "Boosteroid";
      comment = "Boosteroid Cloud Gaming";
      exec = "boosteroid %U";
      categories = [ "Game" ];
      startupWMClass = "Boosteroid";
    })
  ];

  meta = {
    description = "Boosteroid Cloud Gaming Linux client";
    homepage = "https://boosteroid.com";
    license = lib.licenses.unfree;
    mainProgram = "boosteroid";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
