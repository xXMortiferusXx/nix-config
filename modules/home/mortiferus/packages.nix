pkgs: with pkgs; [
  # --- Desktop & Appearance (Theming) ---
  nwg-look
  orchis-theme
  tela-icon-theme
  # catppuccin-gtk  # deaktiviert: python3.14-catppuccin inkompatibel mit neuem matplotlib
  qt6Packages.qt6ct
  libsForQt5.qt5ct
  papirus-icon-theme
  adwaita-icon-theme
  shared-mime-info

  # --- Wayland & System Utilities ---
  grim
  slurp
  wl-clipboard
  cliphist
  udiskie

  # --- System Monitoring & Terminal ---
  btop
  yazi

  # --- Apps & Social ---
  thunar
  discord
  cartridges
  polychromatic
  goverlay
  vulkan-tools

  # --- Office & Media ---
  thunderbird-latest
  libreoffice
  hunspellDicts.de_DE
  hyphenDicts.de-de
  zathura
  loupe
  gimp
  naps2

  # --- Development & 3D Printing ---
  opencode
  prusa-slicer
  orca-slicer

  # --- Python-Umgebung (poe-price-checker) ---
  (python3.withPackages (ps: with ps; [
    pyqt6
    httpx
    pyperclip
    pynput
  ]))
]
