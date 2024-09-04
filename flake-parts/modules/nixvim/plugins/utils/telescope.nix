# --- flake-parts/modules/nixvim/plugins/utils/telescope.nix
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
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel;

  cfg = config.tensorfiles.nixvim.plugins.utils.telescope;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.utils.telescope = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      keymaps = [
        {
          mode = "n";
          key = "<leader>/";
          action = "<cmd>Telescope live_grep<CR>";
          options = {
            desc = "Grep in project";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader><leader>";
          action = "<cmd>Telescope find_files<CR>";
          options = {
            desc = "Find files";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>pb";
          action = "<cmd>Telescope buffers<CR>";
          options = {
            desc = "Telescope buffers";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>pg";
          action = "<cmd>Telescope git_commits<CR>";
          options = {
            desc = "Telescope git commits";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>pf";
          action = "<cmd>Telescope find_files<CR>";
          options = {
            desc = "Telescope files";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>ph";
          action = "<cmd>Telescope man_pages<CR>";
          options = {
            desc = "Telescope man pages";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>pl";
          action = "<cmd>Telescope colorschemes<CR>";
          options = {
            desc = "Telescope colorschemes";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>pc";
          action = "<cmd>Telescope commands<CR>";
          options = {
            desc = "Telescope commands";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>ps";
          action = "<cmd>Telescope snippets<CR>";
          options = {
            desc = "Telescope snippets";
            silent = true;
          };
        }
      ];

      plugins.telescope = {
        enable = _ true;
        extensions = {
          file-browser = {
            enable = _ true;
          };
          fzf-native = {
            enable = _ true;
          };
        };
        settings = {
          defaults.prompt_prefix = _ "🔍";
        };
      };

      extraConfigLua = ''
        require("telescope").setup{
          pickers = {
            colorscheme = {
              enable_preview = true
            }
          }
        }
      '';
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
