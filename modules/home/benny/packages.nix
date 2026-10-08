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
  amberol                # GTK4/libadwaita Audio-Player
  naps2                  # Scanner
]
