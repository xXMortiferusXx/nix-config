# App-Liste für lion (lion-pc) — siehe lion-pc.md "App-Liste"
# Bewusst NICHT enthalten (Raus-Liste): polychromatic, rusty-path-of-building,
# prusa/orca-slicer, ideamaker, python-poE-Env.
# Admin/Wartungs-Basis kommt über gemeinsame System-Module (common.nix etc.).
pkgs: with pkgs; [
  # --- Desktop & Appearance (Theming) — 1:1 wie nex/styx ---
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

  # --- System Monitoring & Terminal ---
  btop
  yazi

  # --- Apps & Social ---
  thunar
  discord
  cartridges
  goverlay
  vulkan-tools
  opencode

  # --- Gaming ---
  prismlauncher   # Offizieller Launcher ist auf NixOS (1.19+) kaputt → Prism als Standard
  vinegar         # Roblox Studio nativer Weg (Flatpak-Login ging nicht: Sandbox blockt OAuth-WebView)

  # --- Office & Media (kindgerecht, leicht) ---
  loupe
  gimp
  qalculate-gtk
  zathura
]