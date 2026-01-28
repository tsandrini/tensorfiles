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

  dmsToWal = pkgs.writeShellApplication {
    name = "dms-to-wal";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail

      CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"
      DMS_COLORS="$CACHE_HOME/DankMaterialShell/dms-colors.json"
      DMS_CACHE="$CACHE_HOME/DankMaterialShell/cache.json"

      WAL_DIR="$CACHE_HOME/wal"
      COLORS_JSON="$WAL_DIR/colors.json"
      PYWALFOX_JSON="$WAL_DIR/dank-pywalfox.json"
      SEQUENCES="$WAL_DIR/sequences"

      mkdir -p "$WAL_DIR"

      if [[ ! -r "$DMS_COLORS" ]]; then
        echo "dms-to-wal: missing DMS colors at $DMS_COLORS" >&2
        exit 0
      fi

      # Try to discover the current wallpaper path (for pywalfox compatibility).
      # Best-effort: if not found, set to empty string (still better than missing key).
      wallpaper=""
      if [[ -r "$DMS_CACHE" ]]; then
        wallpaper="$(jq -r '
          .wallpaper
          // .currentWallpaper
          // .current_wallpaper
          // .lastWallpaper
          // empty
        ' "$DMS_CACHE" 2>/dev/null || true)"
      fi

      # Generate a pywal-ish colors.json from DMS palette
      # Important: capture original input as $dms so reduce doesn't lose access.
      jq --arg wallpaper "$wallpaper" '
        . as $dms
        | def c($i): ($dms.dank16["color"+($i|tostring)].default // $dms.dank16["color"+($i|tostring)].dark // null);

        {
          wallpaper: $wallpaper,
          special: {
            background: $dms.colors.dark.background,
            foreground: $dms.colors.dark.on_background,
            cursor:     $dms.colors.dark.on_background
          },
          colors: (reduce range(0;16) as $i ({}; . + {("color"+($i|tostring)): c($i)}))
        }
      ' "$DMS_COLORS" > "$COLORS_JSON"

      # Pywalfox: DMS doc expects this to exist; many setups read colors.json directly too.
      cp -f "$COLORS_JSON" "$PYWALFOX_JSON"

      # Terminal escape sequences (OSC). One-line blob, like pywal produces.
      # Use ST terminator (\033\) like your example.
      bg="$(jq -r '.special.background' "$COLORS_JSON")"
      fg="$(jq -r '.special.foreground' "$COLORS_JSON")"
      cur="$(jq -r '.special.cursor' "$COLORS_JSON")"

      seq=""

      # 16 base colors
      for i in $(seq 0 15); do
        c="$(jq -r --arg k "color$i" '.colors[$k]' "$COLORS_JSON")"
        seq="''${seq}\033]4;''${i};''${c}\033\\"
      done

      # Foreground/background/cursor
      seq="''${seq}\033]10;''${fg}\033\\"
      seq="''${seq}\033]11;''${bg}\033\\"
      seq="''${seq}\033]12;''${cur}\033\\"

      # A few extra OSC codes that pywal often includes (safe; helps some apps)
      # 13: mouse fg, 17: highlight bg, 19: highlight fg (values reused like typical wal)
      seq="''${seq}\033]13;''${fg}\033\\"
      seq="''${seq}\033]17;''${fg}\033\\"
      seq="''${seq}\033]19;''${bg}\033\\"

      # 232..255 ramp endpoints (pywal writes a couple; harmless)
      seq="''${seq}\033]4;232;''${bg}\033\\"
      seq="''${seq}\033]4;256;''${fg}\033\\"

      # Some builds also emit this final code; keep it for compatibility
      seq="''${seq}\033]708;''${bg}\033\\"

      printf '%b' "$seq" > "$SEQUENCES"
    '';
  };
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

      # Run once each login (so ~/.cache/wal exists even before the first palette change),
      # and also whenever DMS regenerates dms-colors.json.
      systemd.user.services.dms-to-wal = {
        Unit = {
          Description = "Generate pywal artifacts from DMS palette";
          # optional but nice:
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${lib.getExe dmsToWal}";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      systemd.user.paths.dms-to-wal = {
        Unit = {
          Description = "Watch DMS palette and refresh pywal artifacts";
        };
        Path = {
          PathChanged = "%h/.cache/DankMaterialShell/dms-colors.json";
          Unit = "dms-to-wal.service";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      home.packages = [
        pkgs.neovide # This is a simple graphical user interface for Neovim
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.nerd-fonts.symbols-only
        pkgs.noto-fonts
        pkgs.noto-fonts-color-emoji
        pkgs.hicolor-icon-theme
        pkgs.adwaita-icon-theme
        pkgs.papirus-icon-theme
        pkgs.kdePackages.breeze-icons

        pkgs.nautilus
        pkgs.gvfs
        pkgs.udiskie
        pkgs.file-roller
        pkgs.loupe
        pkgs.mpv
        pkgs.vlc
        pkgs.pavucontrol
        pkgs.blueman
        pkgs.kdePackages.qt6ct

        pkgs.kdePackages.gwenview
        pkgs.qimgv
        pkgs.imv
        pkgs.kdePackages.ark
        pkgs.kdePackages.dolphin

        pkgs.matugen

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
        enable = true;

        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };

        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };

      programs.niri = {
        package = pkgs.niri-unstable;

        settings = {
          prefer-no-csd = true;
          screenshot-path = "~/FiberBundle/Images/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"; # TODO
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

          spawn-at-startup = [
            { argv = [ "kdeconnect-indicator" ]; }
          ];

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

              "${mod}+Left".action = a.focus-column-left;
              "${mod}+Down".action = a.focus-window-down;
              "${mod}+Up".action = a.focus-window-up;
              "${mod}+Right".action = a.focus-column-right;

              # --- Workspaces ---
              "${mod}+U".action = a.focus-workspace-down;
              "${mod}+I".action = a.focus-workspace-up;

              # --- Moving stuff ---
              "${mod}+Shift+H".action = a.move-column-left;
              "${mod}+Shift+J".action = a.move-window-down;
              "${mod}+Shift+K".action = a.move-window-up;
              "${mod}+Shift+L".action = a.move-column-right;

              "${mod}+Shift+Left".action = a.move-column-left;
              "${mod}+Shift+Down".action = a.move-window-down;
              "${mod}+Shift+Up".action = a.move-window-up;
              "${mod}+Shift+Right".action = a.move-column-right;

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

              "${mod}+F".action = a.maximize-column;

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
              "${mod}+P".action = dms [
                "notepad"
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

      programs.dank-material-shell = {
        enable = _ true;
        systemd = {
          enable = _ false;
          restartIfChanged = _ true;
        };

        niri = {
          enableSpawn = _ true;
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
