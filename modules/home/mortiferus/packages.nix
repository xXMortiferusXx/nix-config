pkgs: with pkgs; [
  # --- Desktop & Appearance (Theming) ---
  nwg-look
  orchis-theme
  tela-icon-theme
  catppuccin-gtk
  qt6Packages.qt6ct
  libsForQt5.qt5ct
  papirus-icon-theme
  adwaita-icon-theme
  gnome-themes-extra
  shared-mime-info

  # --- Wayland & System Utilities ---
  grim
  slurp
  satty
  swappy
  wf-recorder
  wl-clipboard
  xsel
  cliphist
  udiskie
  cacert
  xdotool
  xclip

  # --- System Monitoring & Terminal ---
  btop
  yazi

  # --- Apps & Social ---
  thunar
  vesktop
  cartridges
  polychromatic

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
