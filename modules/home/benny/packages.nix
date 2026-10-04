# App-Liste für benny
pkgs: with pkgs; [
  # --- Desktop & Appearance (Theming) — 1:1 wie nex/styx/lion ---
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
  goverlay       # GUI fuer MangoHud/vkBasalt/OptiScaler (baut seit nixpkgs a7868a72 wieder)
  opencode

  # --- Gaming ---
  vinegar         # Roblox Studio

  # --- Office & Media ---
  loupe
  gimp
  qalculate-gtk
  zathura
  libreoffice
  hunspellDicts.de_DE    # deutsche Rechtschreibung (LibreOffice)
  hyphenDicts.de-de      # deutsche Silbentrennung (LibreOffice)
  thunderbird            # E-Mail
  mpv                    # Video-Player
  amberol                # Audio-Player (GTK4/libadwaita, Noctalia-Theme)
  naps2                  # Scanner
]
