# --- flake-parts/modules/nixvim/plugins/editor/leetcode.nix
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
{ localFlake, leetcode-nvim }:
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

  cfg = config.tensorfiles.nixvim.plugins.editor.leetcode;
in
{
  options.tensorfiles.nixvim.plugins.editor.leetcode = {
    enable = mkEnableOption ''
      TODO
    '';

    # TODO, uhhh, figure out how to modularize this
    solutionsDir = mkOption {
      type = types.str;
      default = "~/ProjectBundle/tsandrini/leetcode-solutions";
      description = ''
        Directory where you store your leetcode solutions.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      extraPlugins = [
        (pkgs.vimUtils.buildVimPlugin {
          name = "leetcode-nvim";
          src = leetcode-nvim;
          doCheck = false;
        })
      ];

      extraConfigLua = ''
        require('leetcode').setup({
          lang = "rust",
          storage = {
            home = "${cfg.solutionsDir}",
            cache = vim.fn.stdpath("cache") .. "/leetcode",
          },
          -- image_support = true,
        })
      '';
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
