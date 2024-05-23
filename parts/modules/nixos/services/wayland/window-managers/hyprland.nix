# --- modules/services/wayland/window-managers/hyprland.nix
#
# Author:  tsandrini <tomas.sandrini@seznam.cz>
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
{
  pkgs,
  config,
  lib,
  inputs,
  system,
  ...
}:
with builtins;
with lib;
let
  cfg = config.tensorfiles.services.wayland.window-managers.hyprland;
  _ = mkOverride 500;

  agsCheck =
    (hasAttr "wayland" config.tensorfiles.programs)
    && (hasAttr "ags" config.tensorfiles.programs.wayland)
    && config.tensorfiles.programs.wayland.ags.enable;
in
{
  options.tensorfiles.services.wayland.window-managers.hyprland =
    with types;
    with tensorfiles.options;
    {
      enable = mkEnableOption ''
        TODO
      '';

      home = {
        enable = mkHomeEnableOption;

        settings = mkHomeSettingsOption (_user: {
          pywal = {
            enable = mkPywalEnableOption;
          };

          ags = {
            enable = mkAlreadyEnabledOption ''
              Enable ags hyprland integration

              This includes
              1. launching ags
              2. mediakeys via ags
            '';
          };
        });
      };
    };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.hyprland = {
        enable = _ true;
        package = _ inputs.hyprland.packages.${system}.hyprland;
      };

      home-manager.users = genAttrs (attrNames cfg.home.settings) (
        _user:
        let
          userCfg = cfg.home.settings.${_user};
        in
        {
          services.safeeyes.enable = _ true;
          services.flameshot.enable = _ true; # test out

          home.packages = with pkgs; [
            playerctl
            xdg-utils # create maybe a base graphical?
            hyprpicker
            gtklock
            xdg-desktop-portal-hyprland
            swww
            grim # TODO all of the following dependencies should be wrapped
            slurp
            sassc
            brightnessctl
            wf-recorder
            wayshot
            imagemagick
            wl-gammactl
            swappy
            (python3.withPackages (ps: with ps; [ python-pam ]))
            inputs.ags.packages.${system}.default
            copyq
          ]; # TODO move

          wayland.windowManager.hyprland = {
            enable = _ true;
            package = _ inputs.hyprland.packages.${system}.hyprland;
            settings = {
              exec-once = [ "copyq" ] ++ (optional (agsCheck && userCfg.ags.enable) "ags");

              # TODO move this part to concrete host definitions
              monitor = [ "eDP-1, 1920x1080, 0x0, 1" ];

              general = {
                gaps_in = _ 5;
                gaps_out = _ 5;
                border_size = _ 1;
                layout = _ "dwindle";
                resize_on_border = _ true;
                allow_tearing = _ true;
              };

              gestures = {
                workspace_swipe = _ "on";
                workspace_swipe_direction_lock = _ false;
                workspace_swipe_forever = _ true;
                workspace_swipe_numbered = _ true;
              };

              group = {
                groupbar = {
                  font_size = _ 16;
                  gradients = _ false;
                };
                # TODO col_border_active_color
              };

              decoration = {
                rounding = _ 14;
                blur = {
                  enabled = _ false;
                  size = _ 10;
                  passes = _ 3;
                  new_optimizations = _ true;
                  brightness = _ 1.0;
                  contrast = _ 1.0;
                  noise = _ 2.0e-2;
                };
                drop_shadow = _ true;
                shadow_ignore_window = _ true;
                shadow_offset = _ "0 2";
                shadow_range = _ 20;
                shadow_render_power = _ 3;
                "col.shadow" = _ "rgba(00000055)";
              };

              animations = {
                enabled = _ true;
                animation = [
                  "border, 1, 2, default"
                  "fade, 1, 4, default"
                  "windows, 1, 3, default, popin 80%"
                  "workspaces, 1, 2, default, slide"
                ];
              };

              dwindle = {
                pseudotile = _ "yes";
                preserve_split = _ "yes";
              };

              misc = {
                layers_hog_keyboard_focus = _ false;
                disable_splash_rendering = _ true;
                # force_default_wallpaper = 0;
              };

              input = {
                kb_layout = _ "us,cz";
                kb_options = _ "grp:alt_shift_toggle";
                kb_variant = _ ",qwerty";
                follow_mouse = _ 1;
                touchpad = {
                  natural_scroll = _ "yes";
                  disable_while_typing = _ true;
                  drag_lock = _ true;
                };
                sensitivity = _ 0;
                float_switch_override_focus = _ 2;
              };
              binds = {
                allow_workspace_cycles = _ true;
              };

              bind =
                [
                  "SUPER, Return, exec, kitty"
                  "SUPER SHIFT, Q, killactive,"
                  "SUPER, D, exec, anyrun"

                  "SUPER, T, togglefloating"
                  "SUPER, R, togglesplit"
                  "SUPER, Tab, workspace, previous"
                  "SUPER, Space, fullscreen"

                  "SUPER, h, movefocus, l"
                  "SUPER, l, movefocus, r"
                  "SUPER, k, movefocus, u"
                  "SUPER, j, movefocus, d"

                  "SUPER SHIFT, j, swapnext,"
                  "SUPER SHIFT, k, swapnext, prev"

                  "SUPER,B,layoutmsg,swapwithmaster master" # TODO debug
                ]
                ++ (map (x: "SUPER, ${toString x}, workspace, ${toString x}") [
                  1
                  2
                  3
                  4
                  5
                  6
                  7
                  8
                  9
                ])
                ++ (map (x: "SUPER SHIFT, ${toString x}, movetoworkspace, ${toString x}") [
                  1
                  2
                  3
                  4
                  5
                  6
                  7
                  8
                  9
                ]);

              bindm = [
                "SUPER, mouse:273, resizewindow"
                "SUPER, mouse:272, movewindow"
              ];

              binde = [
                "SUPER CTRL, k, resizeactive, 0 -20"
                "SUPER CTRL, j, resizeactive, 0 20"
                "SUPER CTRL, l, resizeactive, 20 0"
                "SUPER CTRL, h, resizeactive, -20 0"
              ];

              bindl =
                if (agsCheck && userCfg.ags.enable) then
                  [
                    ", XF86AudioPlay, exec, ags run-js 'mpris.players.pop()?.playPause()'"
                    ", XF86AudioPrev, exec, ags run-js 'mpris.players.pop()?.previous()'"
                    ", XF86AudioNext, exec, ags run-js 'mpris.players.pop()?.next()'"
                    ", XF86AudioStop, exec, ags run-js 'mpris.players.pop()?.stop()'"
                    ", XF86AudioPause, exec, ags run-js 'mpris.players.pop()?.pause()'"

                    ", XF86AudioMute, exec, ags run-js 'audio.speaker.isMuted = !audio.speaker.isMuted'"
                    ", XF86AudioMicMute, exec, ags run-js 'audio.microphone.isMuted = !audio.microphone.isMuted'"
                  ]
                else
                  [
                    ", XF86AudioPlay, exec, playerctl play-pause"
                    ", XF86AudioPrev, exec, playerctl previous"
                    ", XF86AudioNext, exec, playerctl next"
                    ", XF86AudioStop, exec, playerctl stop"
                    ", XF86AudioPause, exec, playerctl pause"

                    ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
                    ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
                  ];

              bindle =
                if (agsCheck && userCfg.ags.enable) then
                  [
                    ", XF86AudioRaiseVolume, exec, ags run-js 'audio.speaker.volume += 0.05; indicator.speaker()'"
                    ", XF86AudioLowerVolume, exec, ags run-js 'audio.speaker.volume -= 0.05; indicator.speaker()'"
                    ", XF86MonBrightnessUp, exec, ags run-js 'brightness.screen += 0.05; indicator.display()'"
                    ", XF86MonBrightnessDown, exec, ags run-js 'brightness.screen -= 0.05; indicator.display()'"
                    ", XF86KbdBrightnessUp,     exec, ags run-js 'brightness.kbd++; indicator.kbd()'"
                    ", XF86KbdBrightnessDown,   exec, ags run-js 'brightness.kbd--; indicator.kbd()'"
                  ]
                else
                  [
                    ", XF86AudioRaiseVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 5%+"
                    ", XF86AudioLowerVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 5%-"
                    ", XF86MonBrightnessUp, exec, brightnessctl s +5%"
                    ", XF86MonBrightnessDown, exec, brightnessctl s -5%"
                  ];
            };
          };
        }
      );
    }
    # |----------------------------------------------------------------------| #
  ]);
}
