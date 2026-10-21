# App-Liste für benny
pkgs: with pkgs; [
  # --- Desktop & Appearance (Theming) ---
  nwg-look
  tela-icon-theme
  qt6Packages.qt6ct
  libsForQt5.qt5ct
  papirus-icon-theme
  adwaita-icon-theme
  shared-mime-info
  adw-gtk3

  # --- Wayland & System Utilities ---
  grim
  slurp
  wl-clipboard
  cliphist
  udiskie
  ddcutil    # Monitor-Helligkeit per DDC/CI

  # --- System Monitoring & Terminal ---
  btop
  yazi

  # --- Python (Noctalia-Plugin "discord-voice" braucht python3 auf PATH) ---
  python3

  # --- Apps & Social ---
  thunar
  discord
  cartridges
  vulkan-tools
  goverlay       # GUI fuer MangoHud/vkBasalt/OptiScaler
  opencode

  # --- Gaming ---
  vinegar         # Roblox Studio

  # --- Office & Media ---
  loupe
  gimp
  qalculate-gtk
  zathura
  libreoffice
  hunspellDicts.de_DE    # deutsche Rechtschreibung
  hyphenDicts.de-de      # deutsche Silbentrennung
  thunderbird
  mpv
  naps2                  # Scanner

  # Edge fuer Boosteroid (offiziell empfohlen). Beide Binaries wrappen und die
  # Desktop-Eintraege auf den Wrapper zeigen lassen, damit das normale
  # Edge-Menue die VA-API-Flags fuer die HD 4000 immer mitbekommt.
  (microsoft-edge.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      for b in $out/bin/microsoft-edge $out/bin/microsoft-edge-stable; do
        [ -e "$b" ] || continue
        wrapProgram "$b" \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=VaapiVideoDecoder,VaapiVideoDecodeLinuxGL,VaapiVideoEncoder" \
          --add-flags "--use-gl=angle --use-angle=gl" \
          --add-flags "--enable-zero-copy --ignore-gpu-blocklist"
      done
      for f in $out/share/applications/*.desktop; do
        substituteInPlace "$f" --replace "${microsoft-edge}/bin/" "$out/bin/"
        substituteInPlace "$f" --replace "${microsoft-edge.bin or microsoft-edge}/bin/" "$out/bin/"
      done
    '';
  }))
]
