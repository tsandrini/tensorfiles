# --- parts/modules/home-manager/programs/terminals/kitty.nix
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
  pkgs,
  self,
  inputs,
  ...
}:
with builtins;
with lib; let
  tensorfiles = self.lib;
  inherit (tensorfiles) mkOverrideAtHmModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.hm.programs.terminals.kitty;
  _ = mkOverrideAtHmModuleLevel;

  nvimScrollbackCheck = cfg.nvim-scrollback.enable && (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.editors.neovim");
in {
  options.tensorfiles.hm.programs.terminals.kitty = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles terminals.kitty colorscheme generator.
    '');

    nvim-scrollback = {
      enable = mkAlreadyEnabledOption ''
        TODO
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      programs.kitty = {
        enable = _ true;
        font = {
          package = _ pkgs.meslo-lgs-nf;
          name = _ "MesloLGS NF";
        };
        settings = {
          background_opacity = _ "0.8";
          enable_audio_bell = _ false;
          # kitty-scrollback.nvim
          allow_remote_control = mkIf nvimScrollbackCheck (_ true);
          shell_integration = mkIf nvimScrollbackCheck (_ "enabled");
        };
        extraConfig = mkBefore ''
          ${
            if nvimScrollbackCheck
            then ''
              listen_on unix:/tmp/kitty
              action_alias kitty_scrollback_nvim kitten ${inputs.kitty-scrollback-nvim}/python/kitty_scrollback_nvim.py --no-nvim-args
              map ctrl+space kitty_scrollback_nvim
              mouse_map kitty_mod+right press ungrabbed combine : mouse_select_command_output : kitty_scrollback_nvim --config ksb_builtin_last_visited_cmd_output
            ''
            else ""
          }
        '';
      };

      xdg.configFile."kitty/open-actions.conf" = {
        text = mkBefore ''
          protocol file
          fragment_matches [0-9]+
          action launch --type=overlay $EDITOR +$FRAGMENT $FILE_PATH

          protocol file
          mime text/*
          action launch --type=overlay $EDITOR $FILE_PATH

          protocol file
          mime image/*
          action launch --type=overlay kitty +kitten icat --hold $FILE_PATH

          protocol filelist
          action send_text all ''${FRAGMENT}
        '';
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
