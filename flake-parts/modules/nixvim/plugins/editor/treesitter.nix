# --- flake-parts/modules/nixvim/plugins/editor/treesitter.nix
#
# Author:  tsandrini <t@tsandrini.sh>
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
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel;

  cfg = config.tensorfiles.nixvim.plugins.editor.treesitter;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.editor.treesitter = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      plugins.treesitter = {
        enable = _ true;
        settings = {
          indent.enable = _ true;
          highlight.enable = _ true;
        };
        folding = _ true;
        nixvimInjections = _ true;
        nixGrammars = _ true;
        # grammarPackages = _ pkgs.vimPlugins.nvim-treesitter.allGrammars;
      };

      plugins.treesitter-context = {
        enable = _ true;
      };

      # plugins.treesitter-textobjects = {
      #   enable = _ true;
      #   select = {
      #     enable = _ true;
      #     lookahead = _ true;
      #     keymaps = {
      #       "aa" = _ "@parameter.outer";
      #       "ia" = _ "@parameter.inner";
      #       "af" = _ "@function.outer";
      #       "if" = _ "@function.inner";
      #       "ac" = _ "@class.outer";
      #       "ic" = _ "@class.inner";
      #       "ii" = _ "@conditional.inner";
      #       "ai" = _ "@conditional.outer";
      #       "il" = _ "@loop.inner";
      #       "al" = _ "@loop.outer";
      #       "at" = _ "@comment.outer";
      #     };
      #   };
      #   # swap = {
      #   #   enable = true;
      #   #   swapNext = {
      #   #     "<leader>a" = "@parameters.inner";
      #   #   };
      #   #   swapPrevious = {
      #   #     "<leader>A" = "@parameter.outer";
      #   #   };
      #   # };
      # };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
