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
  config,
  lib,
  inputs,
  system,
  user ? "root",
  ...
}:
with builtins;
with lib; let
  inherit (tensorfiles.modules) mkOverrideAtProfileLevel;

  cfg = config.tensorfiles.services.wayland.window-managers.hyprland;
  _ = mkOverrideAtProfileLevel;
in {
  options.tensorfiles.services.wayland.window-managers.hyprland = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      TODO
    '');

    home = {
      enable = mkHomeEnableOption;

      settings = mkHomeSettingsOption (_user: {
        pywal = {enable = mkPywalEnableOption;};
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

      home-manager.users.${user} = {
        wayland.windowManager.hyprland = {
          enable = _ true;
          package = _ inputs.hyprland.packages.${system}.hyprland;
          settings = {
            monitor = [
              "eDP-1, 1920x1080, 0x0, 1"
            ];

            general = {
              layout = "dwindle";
              resize_on_border = true;
            };

            misc = {
              layers_hog_keyboard_focus = false;
              disable_splash_rendering = true;
              # force_default_wallpaper = 0;
            };

            input = {
              kb_layout = _ "us,cz";
              kb_options = _ "grp:alt_shift_toggle";
              kb_variant = _ ",qwerty";
              follow_mouse = 1;
              touchpad = {
                natural_scroll = "yes";
                disable_while_typing = true;
                drag_lock = true;
              };
              sensitivity = 0;
              float_switch_override_focus = 2;
            };
            binds = {
              allow_workspace_cycles = true;
            };

            dwindle = {
              pseudotile = "yes";
              preserve_split = "yes";
              # no_gaps_when_only = "yes";
            };
            gestures = {
              workspace_swipe = "on";
              workspace_swipe_direction_lock = false;
              workspace_swipe_forever = true;
              workspace_swipe_numbered = true;
            };

            windowrule = let
              f = regex: "float, ^(${regex})$";
            in [
              (f "pavucontrol")
              (f "nm-connection-editor")
              (f "blueberry.py")
              (f "Color Picker")
              (f "xdg-desktop-portal")
              (f "xdg-desktop-portal-gnome")
              (f "transmission-gtk")
              "workspace 7, title:Spotify"
            ];

            bind = let
              binding = mod: cmd: key: arg: "${mod}, ${key}, ${cmd}, ${arg}";
              mvfocus = binding "SUPER" "movefocus";
              ws = binding "SUPER" "workspace";
              resizeactive = binding "SUPER CTRL" "resizeactive";
              mvactive = binding "SUPER ALT" "moveactive";
              mvtows = binding "SUPER SHIFT" "movetoworkspace";
              arr = [1 2 3 4 5 6 7 8 9];
            in
              [
                "SUPER, Return, exec, kitty"
                "SUPER, T, exec, firefox"
                "SUPER, F, exec, kitty -e lf"

                "ALT, Tab, focuscurrentorlast"
                "CTRL ALT, Delete, exit"
                "ALT, Q, killactive"
                "SUPER, F, togglefloating"
                "SUPER, G, fullscreen"
                "SUPER, O, fakefullscreen"
                "SUPER, P, togglesplit"

                (mvfocus "k" "u")
                (mvfocus "j" "d")
                (mvfocus "l" "r")
                (mvfocus "h" "l")
                (ws "left" "e-1")
                (ws "right" "e+1")
                (mvtows "left" "e-1")
                (mvtows "right" "e+1")
                (resizeactive "k" "0 -20")
                (resizeactive "j" "0 20")
                (resizeactive "l" "20 0")
                (resizeactive "h" "-20 0")
                (mvactive "k" "0 -20")
                (mvactive "j" "0 20")
                (mvactive "l" "20 0")
                (mvactive "h" "-20 0")
              ]
              ++ (map (i: ws (toString i) (toString i)) arr)
              ++ (map (i: mvtows (toString i) (toString i)) arr);

            bindm = [
              "SUPER, mouse:273, resizewindow"
              "SUPER, mouse:272, movewindow"
            ];

            decoration = {
              drop_shadow = "yes";
              shadow_range = 8;
              shadow_render_power = 2;
              "col.shadow" = "rgba(00000044)";

              dim_inactive = false;

              # blur = {
              #   enabled = true;
              #   size = 8;
              #   passes = 3;
              #   new_optimizations = "on";
              #   noise = 0.01;
              #   contrast = 0.9;
              #   brightness = 0.8;
              # };
            };

            animations = {
              enabled = "yes";
              bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
              animation = [
                "windows, 1, 5, myBezier"
                "windowsOut, 1, 7, default, popin 80%"
                "border, 1, 10, default"
                "fade, 1, 7, default"
                "workspaces, 1, 6, default"
              ];
            };
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
