# --- flake-parts/modules/nixvim/plugins/editor/buffer-manager.nix
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
{ localFlake, buffer_manager-nvim }:
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

  cfg = config.tensorfiles.nixvim.plugins.editor.buffer-manager;
in
# _ = mkOverrideAtNixvimModuleLevel;
{
  options.tensorfiles.nixvim.plugins.editor.buffer-manager = {
    enable = mkEnableOption ''
      TODO
    '';

    withKeymaps =
      mkEnableOption ''
        Enable the related included keymaps.
      ''
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      extraPlugins = [
        (pkgs.vimUtils.buildVimPlugin {
          name = "buffer_manager.nvim";
          doCheck = false;
          src = buffer_manager-nvim;
          # src = pkgs.fetchFromGitHub {
          #   owner = "j-morano";
          #   repo = "buffer_manager.nvim";
          #   rev = "03df0142e60cdf3827d270f01ccb36999d5a4e08";
          #   hash = "sha256-sIkz5jkt+VkZNbiHRB7E+ttcm9XNtDiI/2sTyyYd1gg=";
          # };
        })
      ];

      extraConfigLua = ''
        require("buffer_manager").setup({
          win_extra_options = {
            number = true,
            relativenumber = true,
          },
        })
      '';
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.withKeymaps {
      keymaps = [
        {
          mode = "n";
          key = "<leader>bb";
          action = ":lua require(\"buffer_manager.ui\").toggle_quick_menu()<CR>";
          options = {
            desc = "Buffers browser";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>be";
          action = ":lua require(\"buffer_manager.ui\").toggle_quick_menu()<CR>";
          options = {
            desc = "Buffers browser";
            silent = true;
          };
        }
      ];
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
