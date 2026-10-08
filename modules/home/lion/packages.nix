# App-Liste für lion (lion-pc).
# Admin/Wartungs-Basis kommt über gemeinsame System-Module.
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

  # --- Apps & Social ---
  thunar
  discord
  cartridges
  goverlay       # GUI fuer MangoHud/vkBasalt/OptiScaler
  vulkan-tools
  opencode

  # --- Gaming ---
  prismlauncher   # offizieller Launcher auf NixOS kaputt -> Prism als Standard
  vinegar         # Roblox Studio native

  # --- Office & Media (kindgerecht, leicht) ---
  loupe
  gimp
  qalculate-gtk
  zathura
  thunderbird
  mpv
  amberol        # GTK4/libadwaita Audio-Player
]