# --- flake-parts/modules/home-manager/programs/niri-flake.nix
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
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    types
    ;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel;

  cfg = config.tensorfiles.hm.programs.niri-flake;
  _ = mkOverrideAtHmModuleLevel;

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
  options.tensorfiles.hm.programs.niri-flake = {
    enable = mkEnableOption ''
      TODO
    '';

    binds = {
      mod = mkOption {
        type = types.str;
        default = "Mod";
        description = "Default modkey to be used";
      };

      dms = {
        enable = mkEnableOption "Enables various default DMS keybinds";
      };

      flameshot = {
        enable = mkEnableOption "Enables flameshot as the screenshot backend for niri";
      };
    };
  };

  imports = [
    # TODO: This is problematic, we would ideally import `inputs.niri.homeModules.niri`
    # however, `inputs.dms.homeModules.niri` also includes this module and that needs
    # to be imported as well, importing both leads to conflict so this leads us
    # with only a single option to import only `inputs.dms.homeModules.niri`, but
    # we logically can't do that here => we import nothing 💀💀💀

    # inputs.niri.homeModules.niri
  ];

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.packages = [ toggleEdp ];

      programs.niri = {
        package = _ pkgs.niri-unstable;
        settings = {
          prefer-no-csd = _ true;
          workspaces = {
            "01" = {
              name = _ "1";
            };
            "02" = {
              name = _ "2";
            };
            "03" = {
              name = _ "3";
            };
            "04" = {
              name = _ "4";
            };
            "05" = {
              name = _ "5";
            };
            "06" = {
              name = _ "6";
            };
            "07" = {
              name = _ "7";
            };
            "08" = {
              name = _ "8";
            };
          };

          input = {
            keyboard = {
              xkb = {
                layout = _ "us,cz";
                variant = _ ",qwerty";
                options = _ "grp:alt_shift_toggle";
              };

              track-layout = _ "global";
            };
          };

          binds =
            let
              a = config.lib.niri.actions;
            in
            {
              # --- Columns ---
              "${cfg.binds.mod}+H".action = _ a.focus-column-left;
              "${cfg.binds.mod}+J".action = _ a.focus-window-down;
              "${cfg.binds.mod}+K".action = _ a.focus-window-up;
              "${cfg.binds.mod}+L".action = _ a.focus-column-right;

              "${cfg.binds.mod}+MouseBack".action = _ a.focus-column-left;
              "${cfg.binds.mod}+MouseForward".action = _ a.focus-column-right;

              # --- Workspaces ---
              "${cfg.binds.mod}+U".action = _ a.focus-workspace-down;
              "${cfg.binds.mod}+I".action = _ a.focus-workspace-up;

              "${cfg.binds.mod}+WheelScrollDown" = {
                action = _ a.focus-workspace-down;
                cooldown-ms = _ 150;
              };
              "${cfg.binds.mod}+WheelScrollUp" = {
                action = _ a.focus-workspace-up;
                cooldown-ms = _ 150;
              };

              # --- Moving stuff ---
              "${cfg.binds.mod}+Shift+H".action = _ a.move-column-left;
              "${cfg.binds.mod}+Shift+J".action = _ a.move-window-down;
              "${cfg.binds.mod}+Shift+K".action = _ a.move-window-up;
              "${cfg.binds.mod}+Shift+L".action = _ a.move-column-right;

              # --- Resizing windowws ----
              "${cfg.binds.mod}+Left".action = _ (a.set-column-width "-10%");
              "${cfg.binds.mod}+Right".action = _ (a.set-column-width "+10%");
              "${cfg.binds.mod}+Up".action = _ (a.set-window-height "-10%");
              "${cfg.binds.mod}+Down".action = _ (a.set-window-height "+10%");

              # --- Windows and columns manipulation ---
              "${cfg.binds.mod}+F".action = _ a.maximize-column;
              "${cfg.binds.mod}+T".action = _ a.toggle-window-floating;
              "${cfg.binds.mod}+R".action = _ a.switch-preset-column-width;
              "${cfg.binds.mod}+Comma".action = _ a.consume-or-expel-window-right;

              # --- Workspaces ---
              "${cfg.binds.mod}+Tab".action = _ a.focus-workspace-previous;

              "${cfg.binds.mod}+1".action = _ (a.focus-workspace 1);
              "${cfg.binds.mod}+2".action = _ (a.focus-workspace 2);
              "${cfg.binds.mod}+3".action = _ (a.focus-workspace 3);
              "${cfg.binds.mod}+4".action = _ (a.focus-workspace 4);
              "${cfg.binds.mod}+5".action = _ (a.focus-workspace 5);
              "${cfg.binds.mod}+6".action = _ (a.focus-workspace 6);
              "${cfg.binds.mod}+7".action = _ (a.focus-workspace 7);
              "${cfg.binds.mod}+8".action = _ (a.focus-workspace 8);
              "${cfg.binds.mod}+9".action = _ (a.focus-workspace 9);

              # --- Apps ---
              "${cfg.binds.mod}+Q".action = _ a.close-window;
              "${cfg.binds.mod}+W".action = _ a.toggle-overview;
              "${cfg.binds.mod}+Return".action = _ (a.spawn config.home.sessionVariables.TERMINAL);

              "XF86Display" = {
                action = _ (a.spawn [ "toggle-edp" ]);
                allow-when-locked = _ true;
              };
              "Mod+F7" = {
                action = _ (a.spawn [ "toggle-edp" ]);
                allow-when-locked = _ true;
              };
            };
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.binds.dms.enable {
      programs.niri.settings.binds =
        let
          a = config.lib.niri.actions;
          dms =
            cmd:
            _ (
              a.spawn (
                [
                  "dms"
                  "ipc"
                  "call"
                ]
                ++ cmd
              )
            );
        in
        {
          "Ctrl+Alt+Q".action = dms [
            "powermenu"
            "toggle"
          ];

          # DMS toggles
          "${cfg.binds.mod}+Space".action = dms [
            "spotlight"
            "toggle"
          ];
          "${cfg.binds.mod}+V".action = dms [
            "clipboard"
            "toggle"
          ];
          "${cfg.binds.mod}+M".action = dms [
            "processlist"
            "toggle"
          ];
          "${cfg.binds.mod}+P".action = dms [
            "notepad"
            "toggle"
          ];
          "${cfg.binds.mod}+Shift+Q".action = dms [
            ""
            "toggle"
          ];
          "${cfg.binds.mod}+N".action = dms [
            "notifications"
            "toggle"
          ];
          "Ctrl+Alt+L".action = dms [
            "lock"
            "lock"
          ];

          # --- Media keys via DMS IPC ---
          "XF86AudioRaiseVolume" = {
            action = dms [
              "audio"
              "increment"
              "5"
            ];
            allow-when-locked = _ true;
          };
          "XF86AudioLowerVolume" = {
            action = dms [
              "audio"
              "decrement"
              "5"
            ];
            allow-when-locked = _ true;
          };
          "XF86AudioMute" = {
            action = dms [
              "audio"
              "mute"
            ];
            allow-when-locked = _ true;
          };
          "XF86AudioMicMute" = {
            action = dms [
              "audio"
              "micmute"
            ];
            allow-when-locked = _ true;
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
        };
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.binds.flameshot.enable {
      services.flameshot = {
        enable = _ true;
        package = pkgs.flameshot.override {
          enableWlrSupport = true;
        };
        settings = _ {
          General = {
            showStartupLaunchMessage = false;
            useGrimAdapter = true;
          };
        };
      };

      programs.niri.settings.binds =
        let
          a = config.lib.niri.actions;
        in
        {
          "Print".action = _ (
            a.spawn [
              "flameshot"
              "gui"
            ]
          );
          "Ctrl+Print".action = _ (
            a.spawn [
              "flameshot"
              "gui"
            ]
          );
          "Alt+Print".action = _ (
            a.spawn [
              "flameshot"
              "gui"
            ]
          );
        };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
