# --- flake-parts/modules/home-manager/profiles/graphical-dms-niri/default.nix
#
# Author:  tsandrini <t@tsandrini.sh>
# URL:     https://github.com/tsandrini/tensorfiles
# License: MIT
#
# 888                                                .d888 d8b 888
# 888                                               d88P"  Y8P 888
# 888                                               888        888
# 888888 .d88b.  88888b.  .d8888b   .d88b.  888d888 888888 888 888  .d88b.  .d8888b
# 888   d8P  Y8b 888 "88b 88K      d88""88b 888P"   888    888 888 d8P  Y8b 88K
# 888   88888888 888  888 "Y8888b. 888  888 888     888    888 888 88888888 "Y8888b.
# Y88b. Y8b.     888  888      X88 Y88..88P 888     888    888 888 Y8b.          X88
#  "Y888 "Y8888  888  888  88888P'  "Y88P"  888     888    888 888  "Y8888   88888P'
{ localFlake }:
{
  pkgs,
  config,
  lib,
  system,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    getExe
    optional
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmProfileLevel;
  inherit (localFlake.lib.options) mkPywalEnableOption;

  cfg = config.tensorfiles.hm.profiles.graphical-dms-niri;
  _ = mkOverrideAtHmProfileLevel;
in
{
  options.tensorfiles.hm.profiles.graphical-dms-niri = {
    enable = mkEnableOption ''
      TODO
    '';

    include-nvim =
      mkEnableOption ''
        Whether the module should add nvim-ide-config to home.packages
      ''
      // {
        default = true;
      };

    pywal = {
      enable = mkPywalEnableOption;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles.hm = {
        profiles.headless.enable = _ true;
        profiles.headless.include-nvim = _ false;

        programs = {
          newsboat.enable = _ true;
          terminals.wezterm.enable = _ true;
          terminals.ghostty.enable = _ true;
          browsers.firefox.enable = _ true;
          browsers.firefox.userjs.betterfox.enable = _ true;

          thunderbird.enable = _ true;

          niri-flake = {
            enable = _ true;
            binds.dms.enable = _ true;
            binds.flameshot.enable = _ true;
          };
          dank-material-shell = {
            enable = _ true;
            niri-flake.enable = _ true;
          };
          dsearch.enable = _ true;
        };
      };

      home.packages = [
        # --- Fonts ---
        pkgs.neovide # This is a simple graphical user interface for Neovim
        pkgs.nerd-fonts.jetbrains-mono # Nerd Fonts: JetBrains officially created font for developers
        pkgs.nerd-fonts.symbols-only # Nerd Fonts: Just the Nerd Font Icons. I.e Symbol font only
        pkgs.noto-fonts # Beautiful and free fonts for many languages
        pkgs.noto-fonts-color-emoji # Color emoji font

        # --- GTK Stuff & Themes ---
        pkgs.hicolor-icon-theme # Default fallback theme used by implementations of the icon theme specification
        pkgs.adwaita-icon-theme
        pkgs.papirus-icon-theme # Pixel perfect icon theme for Linux
        pkgs.kdePackages.breeze-icons # Breeze icon theme.

        # --- GNOME apps ---
        pkgs.nautilus # File manager for GNOME
        pkgs.gvfs # Virtual Filesystem support library
        pkgs.udiskie # Removable disk automounter for udisks
        pkgs.file-roller # Archive manager for the GNOME desktop environment
        pkgs.loupe # Simple image viewer application written with GTK4 and Rust
        pkgs.evince # GNOME's document viewer
        pkgs.tumbler # D-Bus thumbnailer service
        pkgs.sushi # Quick previewer for Nautilus
        pkgs.ffmpegthumbnailer # Lightweight video thumbnailer
        pkgs.shared-mime-info # Database of common MIME types
        pkgs.desktop-file-utils # Command line utilities for working with .desktop files
        pkgs.gnome-disk-utility # Udisks graphical front-end
        pkgs.totem # Movie player for the GNOME desktop based on GStreamer
        pkgs.dconf-editor # GSettings editor for GNOME
        pkgs.kooha # Elegantly record your screen
        pkgs.gnome-calculator # Application that solves mathematical equations and is suitable as a default application in a Desktop environment
        pkgs.snapshot # Take pictures and videos on your computer, tablet, or phone
        pkgs.baobab # Graphical application to analyse disk usage in any GNOME environment
        pkgs.gnome-connections # Remote desktop client for the GNOME desktop environment
        pkgs.gnome-clocks # Simple and elegant clock application for GNOME
        pkgs.gnome-console # Simple user-friendly terminal emulator for the GNOME desktop
        pkgs.gnome-characters # Simple utility application to find and insert unusual characters
        pkgs.gnome-logs # Log viewer for the systemd journal
        pkgs.gnome-font-viewer # Program that can preview fonts and create thumbnails for fonts
        pkgs.gnome-maps # Map application for GNOME 3
        pkgs.gnome-music # Music player and management application for the GNOME desktop environment
        pkgs.gnome-weather # Access current weather conditions and forecasts
        # pkgs.constrict # Compresses your videos to your chosen file size
        pkgs.gnome-decoder # Scan and generate QR codes
        pkgs.curtail # Simple & useful image compressor
        pkgs.deja-dup # Simple backup tool
        pkgs.impression # Straight-forward and modern application to create bootable drives
        pkgs.tuba # Browse the Fediverse
        pkgs.wike # Wikipedia Reader for the GNOME Desktop
        pkgs.lorem # Generate placeholder text

        # --- KDE apps ---
        # NOTE: I have these mostly just for kdeconnect to work and be able to mount the drives
        pkgs.kdePackages.qt6ct # Qt6 Configuration Tool
        pkgs.kdePackages.ark # File archiver by KDE
        pkgs.kdePackages.kio # KIO
        pkgs.kdePackages.kio-extras # Additional components to increase the functionality of KIO
        pkgs.kdePackages.kio-fuse # FUSE Interface for KIO
        pkgs.kdePackages.dolphin # File manager by KDE
        # pkgs.kdePackages.gwenview # Image viewer by KDE
        # pkgs.qimgv # Qt6 image viewer with optional video support
        # pkgs.imv # Command line image viewer for tiling window managers

        # --- General apps ---
        pkgs.mpv # General-purpose media player, fork of MPlayer and mplayer2
        pkgs.vlc # Cross-platform media player and streaming server
        pkgs.pavucontrol # PulseAudio Volume Control
        pkgs.blueman # GTK-based Bluetooth Manager
        pkgs.matugen # Material you color generation tool

        # pkgs.python3Packages.aiohttp-oauthlib # NOTE: required for calendar integration

      ]
      ++ (optional cfg.include-nvim localFlake.packages.${system}.nvim-ide-config);

      home.shellAliases = {
        "graphical-nvim" = _ (getExe localFlake.packages.${system}.nvim-graphical-config);
        "ide-nvim" = _ (getExe localFlake.packages.${system}.nvim-ide-config);
      };

      home.sessionVariables = {
        # Default programs
        BROWSER = _ "firefox";
        TERMINAL = _ "ghostty";
        IDE = _ "nvim";
        EMAIL = _ "thunderbird";
        QT_QPA_PLATFORMTHEME = _ "qt6ct";
      };

      fonts.fontconfig.enable = _ true;

      gtk = {
        enable = _ true;

        theme = {
          name = _ "adw-gtk3-dark";
          package = _ pkgs.adw-gtk3;
        };

        iconTheme = {
          name = _ "Papirus-Dark";
          package = _ pkgs.papirus-icon-theme;
        };
      };

      services.udiskie = {
        enable = _ true;
        automount = _ false;
        notify = _ true;
        tray = _ "auto";
      };

      services.polkit-gnome.enable = _ true;

      services.kdeconnect = {
        enable = _ true;
        indicator = _ true;
      };

      # TODO move this elsewhere

      xdg.mimeApps.defaultApplications = {
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
        "application/x-pdf" = [ "org.gnome.Evince.desktop" ];

        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "image/webp" = [ "org.gnome.Loupe.desktop" ];
        "image/gif" = [ "org.gnome.Loupe.desktop" ];
        "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];
        "image/bmp" = [ "org.gnome.Loupe.desktop" ];
        "image/tiff" = [ "org.gnome.Loupe.desktop" ];

        "application/zip" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-rar" = [ "org.gnome.FileRoller.desktop" ];

        "video/mp4" = [ "org.gnome.Totem.desktop" ];
        "video/x-matroska" = [ "org.gnome.Totem.desktop" ]; # mkv
        "video/webm" = [ "org.gnome.Totem.desktop" ];
        "video/quicktime" = [ "org.gnome.Totem.desktop" ]; # mov
        "video/x-msvideo" = [ "org.gnome.Totem.desktop" ]; # avi
        "video/x-ms-wmv" = [ "org.gnome.Totem.desktop" ]; # wmv
        "video/mpeg" = [ "org.gnome.Totem.desktop" ]; # mpg/mpeg
        "video/ogg" = [ "org.gnome.Totem.desktop" ];
        "video/x-flv" = [ "org.gnome.Totem.desktop" ];

        "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-bzip2" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-xz" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-zip-compressed" = [ "org.gnome.FileRoller.desktop" ];

        "text/html" = [ "firefox.desktop" ];
        "application/xhtml+xml" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/about" = [ "firefox.desktop" ];
        "x-scheme-handler/unknown" = [ "firefox.desktop" ];

        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];

        # # Text / code -> your Neovim desktop entry
        "text/plain" = [ "neovide.desktop" ];
        "text/markdown" = [ "neovide.desktop" ];
        "application/json" = [ "neovide.desktop" ];
        "application/x-yaml" = [ "neovide.desktop" ];
        "text/x-python" = [ "neovide.desktop" ];
        "text/x-shellscript" = [ "neovide.desktop" ];
        "text/x-csrc" = [ "neovide.desktop" ];
        "text/x-chdr" = [ "neovide.desktop" ];
        "text/x-c++src" = [ "neovide.desktop" ];
        "text/x-c++hdr" = [ "neovide.desktop" ];
        "text/x-rust" = [ "neovide.desktop" ];
        "text/x-go" = [ "neovide.desktop" ];
        "text/x-toml" = [ "neovide.desktop" ];
        "text/x-nix" = [ "neovide.desktop" ];
        "application/xml" = [ "neovide.desktop" ];
        "text/xml" = [ "neovide.desktop" ];
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
