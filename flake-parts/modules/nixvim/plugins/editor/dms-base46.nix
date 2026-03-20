# --- flake-parts/modules/nixvim/plugins/editor/dms-base46.nix
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
{ localFlake, inputs }:
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
    ;
  # inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel;

  cfg = config.tensorfiles.nixvim.plugins.editor.dms-base46;
  # _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.editor.dms-base46 = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      extraPlugins = [
        (pkgs.vimUtils.buildVimPlugin {
          name = "AvengeMedia/base46";
          src = inputs.nvim-base46;
          doCheck = false;
        })
      ];

      extraConfigLua = ''
        require('base46').setup()
      '';

      extraConfigLuaPost = ''
        vim.opt.runtimepath:append(vim.fn.stdpath("config"))

        local function try_dms()
          local paths = vim.fn.globpath(vim.o.runtimepath, "colors/dms.lua", false, true)
          if #paths > 0 then
            return pcall(vim.cmd.colorscheme, "dms")
          end
          return false
        end

        vim.api.nvim_create_autocmd("VimEnter", {
          once = true,
          callback = function()
            vim.schedule(function()
              try_dms()
            end)
          end,
        })
      '';
      # colorscheme = _ "dms";
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
