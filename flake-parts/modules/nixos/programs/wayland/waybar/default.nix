# --- flake-parts/modules/nixos/programs/wayland/waybar/default.nix
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
{ localFlake, inputs }:
{
  config,
  lib,
  system,
  ...
}:
with builtins;
with lib;
let
  inherit (localFlake.lib.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.programs.wayland.waybar;
  _ = mkOverrideAtModuleLevel;
in
{
  options.tensorfiles.programs.wayland.waybar = with types; {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the waybar wayland bar.
    '';

    # home = {
    #   enable = mkHomeEnableOption;

    #   settings = mkHomeSettingsOption (_user: {});
    # };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user: {
        # home.packages = with pkgs; [ meslo-lgs-nf ];
        #
        programs.waybar = {
          enable = _ true;
          style = import ./style.nix { };
          package = _ inputs.nixpkgs-wayland.packages.${system}.waybar;
          settings = {
            mainBar = {
              position = "top";
              layer = "top";
              height = 12;
              margin-top = 0;
              margin-bottom = 0;
              margin-left = 0;
              margin-right = 0;
              modules-left = [
                "custom/launcher"
                "custom/playerctl"
                "custom/playerlabel"
              ];
              modules-center = [
                "hyprland/workspaces"
                # "cpu"
                # "memory"
                # "disk"
              ];

              modules-right = [
                "tray"
                "pulseaudio"
                "clock"
              ];

              clock = {
                format = "󱑍 {:%H:%M}";
                tooltip = false;
                tooltip-format = ''
                  <big>{:%Y %B}</big>
                  <tt><small>{calendar}</small></tt>'';
                format-alt = " {:%d/%m}";
              };

              "hyprland/workspaces" = {
                active-only = false;
                all-outputs = true;
                disable-scroll = false;
                on-scroll-up = "hyprctl dispatch workspace e-1";
                on-scroll-down = "hyprctl dispatch workspace e+1";
                on-click = "activate";
                show-special = "false";
                sort-by-number = true;
                persistent_workspaces = {
                  "*" = 10;
                };
              };

              # "image" = {
              #   exec = "bash ~/.scripts/album_art.sh";
              #   size = 18;
              #   interval = 10;
              # };

              "custom/playerctl" = {
                format = "{icon}";
                return-type = "json";
                max-length = 25;
                exec = ''playerctl -a metadata --format '{"text": "{{artist}} - {{markup_escape(title)}}", "tooltip": "{{playerName}} : {{markup_escape(title)}}", "alt": "{{status}}", "class": "{{status}}"}' -F'';
                on-click-middle = "playerctl play-pause";
                on-click = "playerctl previous";
                on-click-right = "playerctl next";
                format-icons = {
                  Playing = "<span foreground='#6791eb'>󰓇 </span>";
                  Paused = "<span foreground='#cdd6f4'>󰓇 </span>";
                };
                tooltip = false;
              };

              "custom/playerlabel" = {
                format = "<span>{}</span>";
                return-type = "json";
                max-length = 25;
                exec = ''playerctl -a metadata --format '{"text": "{{artist}} - {{markup_escape(title)}}", "tooltip": "{{playerName}} : {{markup_escape(title)}}", "alt": "{{status}}", "class": "{{status}}"}' -F'';
                on-click-middle = "playerctl play-pause";
                on-click = "playerctl previous";
                on-click-right = "playerctl next";
                format-icons = {
                  Playing = "<span foreground='#6791eb'>󰓇 </span>";
                  Paused = "<span foreground='#cdd6f4'>󰓇 </span>";
                };
                tooltip = false;
              };

              memory = {
                format = "󰍛 {}%";
                format-alt = "󰍛 {used}/{total} GiB";
                interval = 30;
              };

              cpu = {
                format = "󰻠 {usage}%";
                format-alt = "󰻠 {avg_frequency} GHz";
                interval = 10;
              };

              disk = {
                format = "󰋊 {}%";
                format-alt = "󰋊 {used}/{total} GiB";
                interval = 30;
                path = "/";
              };

              tray = {
                icon-size = 18;
                spacing = 10;
                tooltip = false;
              };

              pulseaudio = {
                format = "{icon} {volume}%";
                format-muted = "";
                format-icons = {
                  default = [
                    ""
                    ""
                    ""
                  ];
                };
                # on-click = "bash ~/.config/hypr/scripts/volume mute";
                # on-scroll-up = "bash ~/.config/hypr/scripts/volume up";
                # on-scroll-down = "bash ~/.config/hypr/scripts/volume down";
                scroll-step = 5;
                on-click-right = "pavucontrol";
                tooltip = false;
              };

              "custom/launcher" = {
                format = "{}";
                size = 18;
                # on-click = "notify-send -t 1 'swww' '1' & ~/.config/hypr/scripts/wall";
                tooltip = false;
              };
            };
          };
        };
      });
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
