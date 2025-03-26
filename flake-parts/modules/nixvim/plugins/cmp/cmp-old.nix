# --- flake-parts/modules/nixvim/plugins/cmp/cmp.nix
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

  cfg = config.tensorfiles.nixvim.plugins.cmp.cmp;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.cmp.cmp = {
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
      plugins = {
        cmp-emoji = {
          enable = _ true;
        };
        cmp-git = {
          enable = _ true;
        };
        cmp-nvim-lsp = {
          enable = _ true;
        };
        cmp-nvim-lsp-signature-help = {
          enable = _ true;
        };
        cmp-nvim-lsp-document-symbol = {
          enable = _ true;
        };
        cmp-buffer = {
          enable = _ true;
        };
        cmp-path = {
          enable = _ true;
        };
        # cmp_luasnip = {
        #   enable = true;
        # }; # snippets
        # cmp-cmdline = {
        #   enable = _ true;
        # };
        cmp = {
          enable = _ true;
          settings = {
            autoEnableSources = _ true;
            experimental = {
              ghost_text = _ true;
            };
            performance = {
              debounce = _ 60;
              fetchingTimeout = _ 200;
              maxViewEntries = _ 30;
            };
            sources = [
              {
                name = "nvim_lsp";
                priority = 1000;
              }
              { name = "cmp_git"; }
              { name = "nvim_lsp_signature_help"; }
              { name = "nvim_lsp_document_symbol"; }
              { name = "emoji"; }
              # NOTE usually irrelevant and can be autocompleted from telescope
              # { name = "cmdline"; }
              {
                name = "buffer"; # text within current buffer
                option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
                keywordLength = 3;
              }
              {
                name = "path"; # file system paths
                keywordLength = 3;
              }
            ];
            mapping = mkIf cfg.withKeymaps {
              "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
              "<C-Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
              "<C-j>" = "cmp.mapping.select_next_item()";
              "<C-k>" = "cmp.mapping.select_prev_item()";
              "<C-e>" = "cmp.mapping.abort()";
              "<C-b>" = "cmp.mapping.scroll_docs(-4)";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
              "<C-Space>" = "cmp.mapping.complete()";
              "<C-CR>" = "cmp.mapping.confirm({ select = true })";
              "<S-CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })";
            };
          };
        };
      };
      extraConfigLua = ''
        local cmp = require'cmp'

         -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
         cmp.setup.cmdline({'/', "?" }, {
           sources = {
             { name = 'buffer' }
           }
         })

        -- Set configuration for specific filetype.
         cmp.setup.filetype('gitcommit', {
           sources = cmp.config.sources({
             { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
           }, {
             { name = 'buffer' },
           })
         })

        -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
        -- cmp.setup.cmdline(':', {
        --   sources = cmp.config.sources({
        --     { name = 'path' }
        --   }, {
        --     { name = 'cmdline' }
        --   }),
        -- })
      '';
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
