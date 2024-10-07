# --- flake-parts/modules/nixvim/plugins/editor/nvim-ufo.nix
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
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOverride
    ;
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.nixvim.plugins.editor.nvim-ufo;
  _ = mkOverrideAtNixvimModuleLevel;

  lspCheck = isModuleLoadedAndEnabled config "tensorfiles.nixvim.plugins.lsp.lsp";
  treesitterCheck = isModuleLoadedAndEnabled config "tensorfiles.nixvim.plugins.editor.treesitter";
in
{
  options.tensorfiles.nixvim.plugins.editor.nvim-ufo = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      opts =
        let
          _ = mkOverride 850;
        in
        {
          foldcolumn = _ "auto:1";
          foldlevel = _ 99;
          foldlevelstart = _ 99;
          foldenable = _ true;
          fillchars = {
            eob = _ " ";
            fold = _ " ";
            foldopen = _ "";
            foldsep = _ "|";
            foldclose = _ "";
          };
        };

      # TODO treesitter backend borked for some reason
      plugins.nvim-ufo = {
        enable = _ true;
        openFoldHlTimeout = _ 0;
        providerSelector = ''
          function(bufnr, filetype, buftype)
            ${
              if (lspCheck && treesitterCheck) then
                "return {'lsp', 'indent'}"
              else if (lspCheck && !treesitterCheck) then
                "return {'lsp', 'indent'}"
              # else if (!lspCheck && treesitterCheck) then
              #   "return {'treesitter', 'indent'}"
              else
                "return {'indent'}"
            }
          end
        '';
      };

      keymaps = [
        {
          mode = "n";
          key = "zR";
          action.__raw = "require('ufo').openAllFolds";
          options = {
            desc = "Open all folds";
          };
        }
        {
          mode = "n";
          key = "zM";
          action.__raw = "require('ufo').closeAllFolds";
          options = {
            desc = "Close all folds";
          };
        }
        {
          mode = "n";
          key = "zr";
          action.__raw = "require('ufo').openFoldsExceptKinds";
          options = {
            desc = "Close all folds";
          };
        }
        {
          mode = "n";
          key = "zm";
          action.__raw = "require('ufo').closeFoldsWith";
          options = {
            desc = "Close all folds";
          };
        }
      ];

      plugins.statuscol = {
        enable = _ true;
        settings = {
          relculright = _ true;
          ft_ignore = [ "alpha" ];
          segments = [
            {
              click = "v:lua.ScFa";
              text = [
                {
                  __raw = "require('statuscol.builtin').foldfunc";
                }
              ];
            }
            {
              click = "v:lua.ScSa";
              text = [
                " %s"
              ];
            }
            {
              click = "v:lua.ScLa";
              text = [
                {
                  __raw = "require('statuscol.builtin').lnumfunc";
                }
                " "
              ];
            }
          ];
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
