# --- flake-parts/modules/home-manager/programs/terminals/wezterm.nix
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
{ config, lib, ... }:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;
  inherit (localFlake.lib.options) mkPywalEnableOption;

  cfg = config.tensorfiles.hm.programs.terminals.wezterm;
  _ = mkOverrideAtHmModuleLevel;

  pywalCheck = (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.pywal") && cfg.pywal.enable;
in
{
  options.tensorfiles.hm.programs.terminals.wezterm = {
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
      programs.wezterm = {
        enable = _ true;
        enableBashIntegration = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.shells.bash");
        enableZshIntegration = _ (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.shells.zsh");
        extraConfig = ''
          local wezterm = require 'wezterm'
          local config = wezterm.config_builder()
          local modal = wezterm.plugin.require("https://github.com/MLFlexer/modal.wezterm")

          ${
            if pywalCheck then
              ''
                wezterm.add_to_config_reload_watch_list("~/.cache/wal")
                config.color_scheme_dirs = {"~/.cache/wal"}
              ''
            else
              ""
          }

          config.default_cursor_style = 'BlinkingBar'
          config.enable_scroll_bar = true
          config.font_size = 11
          config.use_fancy_tab_bar = false
          config.audible_bell = "Disabled"
          config.window_padding = {
              left = 5,
              right = 5,
              top = 5,
              bottom = 5,
          }
          config.window_background_opacity = 0.8
          config.check_for_updates = false
          config.keys = {
              {
                  key = " ",
                  mods = "CTRL",
                  action = modal.activate_mode("copy_mode")
              }
          }

          wezterm.on("modal.enter", function(name, window, pane)
            modal.set_right_status(window, name)
            modal.set_window_title(pane, name)
          end)

          wezterm.on("modal.exit", function(name, window, pane)
            window:set_right_status("NOT IN A MODE")
            modal.reset_window_title(pane)
          end)

          modal.apply_to_config(config)

          return config
        '';
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
