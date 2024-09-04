# --- flake-parts/modules/nixvim/auto_cmds.nix
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
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;

  cfg = config.tensorfiles.nixvim.auto_cmds;
in
{
  options.tensorfiles.nixvim.auto_cmds = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      autoGroups = {
        highlight_yank = { };
        restore_cursor = { };
      };

      autoCmd = [
        {
          group = "highlight_yank";
          event = [ "TextYankPost" ];
          pattern = "*";
          callback = {
            __raw = ''
              function()
                vim.highlight.on_yank()
              end
            '';
          };
        }
        ## from NVChad https://nvchad.com/docs/recipes (this autocmd will restore the cursor position when opening a file)
        {
          group = "restore_cursor";
          event = [ "BufReadPost" ];
          pattern = "*";
          callback = {
            __raw = ''
              function()
                if
                  vim.fn.line "'\"" > 1
                  and vim.fn.line "'\"" <= vim.fn.line "$"
                  and vim.bo.filetype ~= "commit"
                  and vim.fn.index({ "xxd", "gitrebase" }, vim.bo.filetype) == -1
                then
                  vim.cmd "normal! g`\""
                end
              end
            '';
          };
        }
      ];
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
