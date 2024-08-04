# --- flake-parts/modules/home-manager/services/dunst.nix
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
{ localFlake }:
{
  config,
  lib,
  pkgs,
  ...
}:
with builtins;
with lib;
let
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkPywalEnableOption;

  cfg = config.tensorfiles.hm.services.dunst;
  _ = mkOverrideAtHmModuleLevel;

  pywalCheck = (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.pywal") && cfg.pywal.enable;
in
{
  options.tensorfiles.hm.services.dunst = with types; {
    enable = mkEnableOption ''
      TODO
    '';

    pywal = {
      enable = mkPywalEnableOption;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.packages = with pkgs; [
        iosevka
        libnotify
        (nerdfonts.override { fonts = [ "Iosevka" ]; })
      ];

      systemd.user.tmpfiles.rules = [
        (
          if pywalCheck then
            "L ${config.xdg.configHome}/dunst/dunstrc.generated - - - - ${config.xdg.cacheHome}/wal/dunstrc"
          else
            ""
        )
      ];

      xdg.configFile."wal/templates/dunstrc" = {
        enable = _ pywalCheck;
        text =
          let
            # taken from
            # https://github.com/nix-community/home-manager/blob/master/modules/services/dunst.nix
            yesNo = value: if value then "yes" else "no";
            toDunstIni = generators.toINI {
              mkKeyValue =
                key: value:
                let
                  value' =
                    if isBool value then
                      (yesNo value)
                    else if isString value then
                      ''"${value}"''
                    else
                      toString value;
                in
                "${key}=${value'}";
            };
            patchedSettings = config.services.dunst.settings // {
              frame = {
                color = "{color1}";
              };
              urgency_low = {
                background = "{background}";
                foreground = "#FFFFFF";
              };
              urgency_normal = {
                background = "{color9}";
                foreground = "{foreground}";
              };
              urgency_critical = {
                background = "{color10}";
                foreground = "{foreground}";
              };
            };
          in
          toDunstIni patchedSettings;
      };

      services.dunst = {
        enable = _ true;
        configFile = _ "${config.xdg.configHome}/dunst/dunstrc${(if pywalCheck then ".generated" else "")}";
        iconTheme = {
          name = _ "Arc";
          package = pkgs.arc-icon-theme;
        };
        settings = {
          global = {
            # GEOMETRY
            origin = _ "top-right";
            offset = _ "5x27";
            history_length = _ 20;
            idle_threshold = _ 0;
            monitor = _ 0;
            padding = _ 2;
            separator_color = _ "frame";
            separator_height = _ 2;
            show_age_threshold = _ 60;
            shrink = _ true;
            sort = _ true;
            sticky_history = _ true;
            transparency = _ 10;
            follow = _ "keyboard";
            # TEXT
            font = _ "Iosevka 10";
            line_height = _ 1;
            markup = _ "full";
            alignment = _ "center";
            vertical_alignment = _ "center";
            word_wrap = _ false;
            ellipsize = _ "middle";
            ignore_newline = _ false;
            stack_duplicates = _ true;
            show_indicators = _ true;
            # ICONS
            # icon-theme = _ "Arc";
            # MISC
            # TODO modularize this?
            dmenu = _ "dmenu_run -i -f -fn 'Ubuntu:pixelsize=11:antialias=true:hinting=true' -p 'Run: '";
            browser = _ "${config.home.sessionVariables.BROWSER} --new-tab";
            startup_notification = _ false;
            verbosity = _ "mesg";
            corner_radius = _ 15;
            ignore_dbusclose = _ true;
            # MOUSE
            mouse_left_click = _ "close_current";
            mouse_middle_click = _ "do_action";
            mouse_right_click = _ "do_action";
          };
          frame = {
            width = _ 1;
          };
          urgency_low = {
            timeout = _ 15;
          };
          urgency_normal = {
            timeout = _ 0;
          };
          urgency_critical = {
            timeout = _ 0;
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
