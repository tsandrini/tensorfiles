# --- modules/programs/terminals/kitty.nix
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
  ...
}:
with builtins;
with lib; let
  inherit (tensorfiles.modules) mkOverrideAtModuleLevel;

  cfg = config.tensorfiles.programs.terminals.kitty;
  _ = mkOverrideAtModuleLevel;
in {
  options.tensorfiles.programs.terminals.kitty = with types;
  with tensorfiles.options; {
    enable = mkEnableOption (mdDoc ''
      Enables NixOS module that configures/handles the kitty terminal.
    '');

    home = {
      enable = mkHomeEnableOption;

      settings = mkHomeSettingsOption (_user: {});
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    (mkIf cfg.home.enable {
      home-manager.users = genAttrs (attrNames cfg.home.settings) (_user: let
        userCfg = cfg.home.settings."${_user}";
      in {
        # home.packages = with pkgs; [ meslo-lgs-nf ];

        programs.kitty = {
          enable = _ true;
          font = {
            package = pkgs.meslo-lgs-nf;
            name = "MesloLGS NF";
          };
          settings = {
            background_opacity = "0.8";
            enable_audio_bell = false;
          };
          extraConfig = mkBefore ''
            map ctrl+shift+space show_scrollback
            scrollback_pager bash -c "exec ${pkgs.neovim}/bin/nvim 63<&0 0</dev/null -u NONE -c 'map <silent> q :qa!<CR>' -c 'set shell=bash scrollback=100000 termguicolors laststatus=0 clipboard+=unnamedplus' -c 'autocmd TermEnter * stopinsert' -c 'autocmd TermClose * call cursor(max([0,INPUT_LINE_NUMBER-1])+CURSOR_LINE, CURSOR_COLUMN)' -c 'terminal sed </dev/fd/63 -e \"s/'$'\x1b'''']8;;file:[^\]*[\]//g\" && sleep 0.01 && printf \"'$'\x1b'''']2;\"'"
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
      });
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with tensorfiles.maintainers; [tsandrini];
}
