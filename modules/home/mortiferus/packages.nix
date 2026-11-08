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
  # Noctalia setzt adw-gtk3 als GTK3-Basis-Theme (@define-color Variablen).
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
  goverlay       # GUI fuer MangoHud/vkBasalt/OptiScaler
  vulkan-tools

  # --- Gaming ---
  # 2026-11-08 deaktiviert: 0.3.3 (nixpkgs #582575) baut nicht (vendored aws-lc-sys
  # bentigt System-AWS-LC, findet keine; Tracking #570938, Fix analog zed-editor
  # #583273 erwartbar). Reaktivieren, sobald ein Fix-Commit in nixpkgs landet.
  # rusty-path-of-building
  vinegar         # Roblox Studio native (Wine)

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
    #opencode
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
