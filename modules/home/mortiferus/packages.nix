pkgs: with pkgs; [
  # --- Desktop & Appearance (Theming) ---
  nwg-look
  tela-icon-theme
  # catppuccin-gtk  # deaktiviert: python3.14-catppuccin inkompatibel mit neuem matplotlib
  qt6Packages.qt6ct
  libsForQt5.qt5ct
  papirus-icon-theme
  adwaita-icon-theme
  shared-mime-info
  # Noctalia setzt adw-gtk3 als Basis-Theme fuer GTK3-Apps.
  # adw-gtk3 nutzt @define-color Variablen, die Noctalia generiert,
  # sodass klassische GTK3-Apps (Thunar, NAPS2, etc.) Noctalia-Farben annehmen.
  adw-gtk3

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

  # --- Gaming ---
  rusty-path-of-building

  # --- Office & Media ---
  thunderbird-latest
  libreoffice
  hunspellDicts.de_DE
  hyphenDicts.de-de
  zathura
    loupe
    gimp
    naps2
    qalculate-gtk

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
