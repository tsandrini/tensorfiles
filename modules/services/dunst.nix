# --- modules/services/dunst.nix
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
{ config, lib, pkgs, ... }:
with builtins;
with lib;
let
  inherit (tensorfiles.modules) mkOverrideAtModuleLevel;
  inherit (tensorfiles.nixos) getUserCacheDir getUserConfigDir isPywalEnabled;

  cfg = config.tensorfiles.services.dunst;
  _ = mkOverrideAtModuleLevel;
in {
  options.tensorfiles.services.dunst = with types;
    with tensorfiles.options; {

      enable = mkEnableOption (mdDoc ''
        Enables NixOS module that configures/handles the dunst notification
        manager service.
      '');

      home = {
        enable = mkHomeEnableOption;

        settings = mkHomeSettingsOption (_user: {

          pywal = { enable = mkPywalEnableOption; };

        });
      };
    };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user:
        let
          userCfg = cfg.home.settings."${_user}";
          cacheDir = getUserCacheDir {
            inherit _user;
            cfg = config;
          };
          configDir = getUserConfigDir {
            inherit _user;
            cfg = config;
          };
          isPywalEnabledForUser =
            ((isPywalEnabled config) && userCfg.pywal.enable);
        in {
          home.packages = with pkgs; [
            iosevka
            (nerdfonts.override { fonts = [ "Iosevka" ]; })
          ];

          home.file."${configDir}/wal/templates/dunstrc" = {
            enable = _ (isPywalEnabledForUser);
            text = let
              # taken from
              # https://github.com/nix-community/home-manager/blob/master/modules/services/dunst.nix
              yesNo = value: if value then "yes" else "no";
              toDunstIni = generators.toINI {
                mkKeyValue = key: value:
                  let
                    value' = if isBool value then
                      (yesNo value)
                    else if isString value then
                      ''"${value}"''
                    else
                      toString value;
                  in "${key}=${value'}";
              };
              patchedSettings =
                config.home-manager.users.${_user}.services.dunst.settings // {
                  frame = { color = "{color1}"; };
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
            in toDunstIni patchedSettings;
          };

          systemd.user.tmpfiles.rules = [
            (if (isPywalEnabledForUser) then
              "L ${configDir}/dunst/dunstrc.generated - - - - ${cacheDir}/wal/dunstrc"
            else
              "")
          ];

          services.dunst = {
            enable = _ true;
            configFile = _ "${configDir}/dunst/dunstrc${
                (if isPywalEnabledForUser then ".generated" else "")
              }";
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
                dmenu = _
                  "dmenu_run -i -f -fn 'Ubuntu:pixelsize=11:antialias=true:hinting=true' -p 'Run: '";
                browser = _ "firefox-developer-edition --new-tab";
                startup_notification = _ false;
                verbosity = _ "mesg";
                corner_radius = _ 15;
                ignore_dbusclose = _ true;
                # MOUSE
                mouse_left_click = _ "close_current";
                mouse_middle_click = _ "do_action";
                mouse_right_click = _ "do_action";
              };
              frame = { width = _ 1; };
              urgency_low = { timeout = _ 15; };
              urgency_normal = { timeout = _ 0; };
              urgency_critical = { timeout = _ 0; };
            };
          };
        });
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [ tsandrini ];
}