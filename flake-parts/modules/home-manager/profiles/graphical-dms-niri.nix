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
{ localFlake, inputs }:
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

  cfg = config.tensorfiles.hm.profiles.graphical-dms-niri;
  _ = mkOverrideAtHmProfileLevel;

  toggleEdp = pkgs.writeShellScriptBin "toggle-edp" ''
    set -euo pipefail

    EDP="eDP-1"

    # Extract the block for eDP-1 (from its "Output ..." header until the next "Output ..." or EOF)
    block="$(
      niri msg outputs \
        | awk -v edp="(''${EDP})" '
            $0 ~ "^Output " {
              in_block = ($0 ~ edp)
            }
            in_block { print }
          '
    )"

    # If we didn't find the block at all, bail out (or you could default to "on").
    if [ -z "$block" ]; then
      exit 0
    fi

    if echo "$block" | grep -q "^[[:space:]]*Disabled[[:space:]]*$"; then
      niri msg output "$EDP" on
    else
      niri msg output "$EDP" off
    fi
  '';

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
  };

  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
  ];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles.hm = {
        profiles.headless.enable = _ true;
        profiles.headless.include-nvim = _ false;

        programs = {
          newsboat.enable = _ true;
          terminals.wezterm.enable = _ true;
          browsers.firefox.enable = _ true;
          browsers.firefox.userjs.betterfox.enable = _ true;

          thunderbird.enable = _ true;

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

        toggleEdp
      ]
      ++ (optional cfg.include-nvim localFlake.packages.${system}.nvim-ide-config);

      services.flameshot = {
        enable = _ true;
        package = pkgs.flameshot.override {
          enableWlrSupport = true;
        };
        settings = {
          General = {
            showStartupLaunchMessage = false;
            useGrimAdapter = true;
          };
        };
      };

      home.shellAliases = {
        "graphical-nvim" = _ (getExe localFlake.packages.${system}.nvim-graphical-config);
        "ide-nvim" = _ (getExe localFlake.packages.${system}.nvim-ide-config);
      };

      home.sessionVariables = {
        # Default programs
        BROWSER = _ "firefox";
        TERMINAL = _ "wezterm";
        IDE = _ "nvim";
        EMAIL = _ "thunderbird";
        QT_QPA_PLATFORMTHEME = "qt6ct";
      };

      fonts.fontconfig.enable = _ true;

      gtk = {
        enable = _ true;

        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };

        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
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

      programs.niri = {
        package = _ pkgs.niri-unstable;
        settings = {
          prefer-no-csd = true;
          workspaces = {
            "01" = {
              name = "1";
            };
            "02" = {
              name = "2";
            };
            "03" = {
              name = "3";
            };
            "04" = {
              name = "4";
            };
            "05" = {
              name = "5";
            };
            "06" = {
              name = "6";
            };
            "07" = {
              name = "7";
            };
            "08" = {
              name = "8";
            };
          };

          input = {
            keyboard = {
              xkb = {
                layout = "us,cz";
                variant = ",qwerty";
                options = "grp:alt_caps_toggle";
              };

              track-layout = "global";
            };
          };

          binds =
            let
              a = config.lib.niri.actions;
              mod = "Mod";
              dms =
                cmd:
                a.spawn (
                  [
                    "dms"
                    "ipc"
                    "call"
                  ]
                  ++ cmd
                );
            in
            {
              # --- Columns ---
              "${mod}+H".action = a.focus-column-left;
              "${mod}+J".action = a.focus-window-down;
              "${mod}+K".action = a.focus-window-up;
              "${mod}+L".action = a.focus-column-right;

              "${mod}+MouseBack".action = a.focus-column-left;
              "${mod}+MouseForward".action = a.focus-column-right;

              # --- Workspaces ---
              "${mod}+U".action = a.focus-workspace-down;
              "${mod}+I".action = a.focus-workspace-up;

              "${mod}+WheelScrollDown" = {
                action = a.focus-workspace-down;
                cooldown-ms = 150;
              };
              "${mod}+WheelScrollUp" = {
                action = a.focus-workspace-up;
                cooldown-ms = 150;
              };

              # --- Moving stuff ---
              "${mod}+Shift+H".action = a.move-column-left;
              "${mod}+Shift+J".action = a.move-window-down;
              "${mod}+Shift+K".action = a.move-window-up;
              "${mod}+Shift+L".action = a.move-column-right;

              # --- Resizing windowws ----
              "${mod}+Left".action = a.set-column-width "-10%";
              "${mod}+Right".action = a.set-column-width "+10%";
              "${mod}+Up".action = a.set-window-height "-10%";
              "${mod}+Down".action = a.set-window-height "+10%";

              # Workspaces 1..9
              "${mod}+1".action = a.focus-workspace 1;
              "${mod}+2".action = a.focus-workspace 2;
              "${mod}+3".action = a.focus-workspace 3;
              "${mod}+4".action = a.focus-workspace 4;
              "${mod}+5".action = a.focus-workspace 5;
              "${mod}+6".action = a.focus-workspace 6;
              "${mod}+7".action = a.focus-workspace 7;
              "${mod}+8".action = a.focus-workspace 8;
              "${mod}+9".action = a.focus-workspace 9;

              # "${mod}+F".action = a.maximize-column;
              "${mod}+F".action = a.maximize-column;
              "${mod}+T".action = a.toggle-window-floating;
              "${mod}+R".action = a.switch-preset-column-width;
              "${mod}+Comma".action = a.consume-or-expel-window-right;

              # --- Apps ---
              "${mod}+Space".action = dms [
                "spotlight"
                "toggle"
              ];
              "${mod}+Return".action = a.spawn config.home.sessionVariables.TERMINAL;
              "${mod}+Tab".action = a.focus-workspace-previous;

              # DMS toggles
              "${mod}+V".action = dms [
                "clipboard"
                "toggle"
              ];
              "${mod}+M".action = dms [
                "processlist"
                "toggle"
              ];
              "Ctrl+Alt+Q".action = dms [
                "powermenu"
                "toggle"
              ];
              "${mod}+P".action = dms [
                "notepad"
                "toggle"
              ];
              "${mod}+Shift+Q".action = dms [
                ""
                "toggle"
              ];
              "${mod}+N".action = dms [
                "notifications"
                "toggle"
              ];
              "Ctrl+Alt+L".action = dms [
                "lock"
                "lock"
              ];

              "${mod}+Q".action = a.close-window;
              "${mod}+W".action = a.toggle-overview;

              "Print".action = a.spawn [
                "flameshot"
                "gui"
              ];
              "Ctrl+Print".action = a.spawn [
                "flameshot"
                "gui"
              ];
              "Alt+Print".action = a.spawn [
                "flameshot"
                "gui"
              ];

              # --- Media keys via DMS IPC ---
              "XF86AudioRaiseVolume" = {
                action = dms [
                  "audio"
                  "increment"
                  "5"
                ];
                allow-when-locked = true;
              };
              "XF86AudioLowerVolume" = {
                action = dms [
                  "audio"
                  "decrement"
                  "5"
                ];
                allow-when-locked = true;
              };
              "XF86AudioMute" = {
                action = dms [
                  "audio"
                  "mute"
                ];
                allow-when-locked = true;
              };
              "XF86AudioMicMute" = {
                action = dms [
                  "audio"
                  "micmute"
                ];
                allow-when-locked = true;
              };

              # Media playback via DMS (MPRIS)
              "XF86AudioPlay".action = dms [
                "mpris"
                "playPause"
              ];
              "XF86AudioPause".action = dms [
                "mpris"
                "pause"
              ];
              "XF86AudioNext".action = dms [
                "mpris"
                "next"
              ];
              "XF86AudioPrev".action = dms [
                "mpris"
                "previous"
              ];
              "XF86AudioStop".action = dms [
                "mpris"
                "stop"
              ];

              "XF86MonBrightnessUp".action = dms [
                "brightness"
                "increment"
                "10"
                ""
              ];
              "XF86MonBrightnessDown".action = dms [
                "brightness"
                "decrement"
                "10"
                ""
              ];

              # NOTE: just a quickfix when I need to leave and just pull cords out
              "XF86Display".action = a.spawn [ "toggle-edp" ];
              "Mod+F7".action = a.spawn [ "toggle-edp" ];
            };
        };
      };

      # TODO move this elsewhere
      systemd.user.tmpfiles.rules = [
        "d %h/.cache/wal 0700 - - -"
        "L+ %h/.cache/wal/colors.json - - - - %h/.cache/wal/dank-pywalfox.json"
      ];

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

      programs.dank-material-shell = {
        enable = _ true;
        systemd = {
          enable = _ true;
          restartIfChanged = _ true;
        };

        niri = {
          enableSpawn = _ false;
          enableKeybinds = _ false;
          includes = {
            enable = _ true;
            override = _ true;
            filesToInclude = [
              "alttab"
              "binds"
              "cursor"
              "colors"
              "layout"
              "outputs"
              "wpblur"
            ];
          };
        };

        enableSystemMonitoring = _ true;
        enableVPN = _ true;
        enableDynamicTheming = _ true;
        enableAudioWavelength = _ true;
        enableCalendarEvents = _ true;
        enableClipboardPaste = _ true;
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
