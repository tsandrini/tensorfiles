# --- flake-parts/modules/nixvim/plugins/cmp/cmp.nix
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
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkEnableOption;
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel mkOverrideAtNixvimProfileLevel isModuleLoadedAndEnabled;

  cfg = config.tensorfiles.nixvim.plugins.cmp.cmp;
  _ = mkOverrideAtNixvimModuleLevel;

  copilot-lua-check = isModuleLoadedAndEnabled config "tensorfiles.nixvim.plugins.editor.copilot-lua";

  get_bufnrs.__raw = ''
    function()
      local buf_size_limit = 1024 * 1024 -- 1MB size limit
      local bufs = vim.api.nvim_list_bufs()
      local valid_bufs = {}
      for _, buf in ipairs(bufs) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf)) < buf_size_limit then
          table.insert(valid_bufs, buf)
        end
      end
      return valid_bufs
    end
  '';
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

    copilot-cmp = {
      enable = mkEnableOption ''
        Enable the copilot-cmp integration.
      '' // { default = true; };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      opts.completeopt = [
        "menu"
        "menuone"
        "noselect"
      ];

      plugins.luasnip = {
        enable = true;
        settings = {
          enable_autosnippets = true;
        };
        fromVscode = [
          {
            lazyLoad = true;
            paths = "${pkgs.vimPlugins.friendly-snippets}";
          }
        ];
      };

      plugins = {
        cmp = {
          enable = _ true;
          autoEnableSources = _ true;
          settings = {
            performance = {
              # maxViewEntries = _ 100;
              # fetchingTimeout = _ 200;
            };
            experimental = {
              ghost_text = _ true;
            };
            mapping = {
              "<C-d>" = "cmp.mapping.scroll_docs(-4)";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
              "<C-Space>" = "cmp.mapping.complete()";
              "<C-e>" = "cmp.mapping.close()";
              "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item({behavior = cmp.SelectBehavior.Select}), {'i', 's'})";
              "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item({behavior = cmp.SelectBehavior.Select}), {'i', 's'})";
              "<C-j>" = "cmp.mapping(cmp.mapping.select_next_item({behavior = cmp.SelectBehavior.Select}), {'i', 's'})";
              "<C-k>" = "cmp.mapping(cmp.mapping.select_prev_item({behavior = cmp.SelectBehavior.Select}), {'i', 's'})";
              "<CR>" = "cmp.mapping.confirm({ select = false, behavior = cmp.ConfirmBehavior.Replace })";
            };
            preselect = "cmp.PreselectMode.None";
            # snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
            sources = [
              {
                name = "nvim_lsp";
                priority = 1100;
                # group_index = 2;
                option = {
                  inherit get_bufnrs;
                };
              }
              {
                name = "nvim_lsp_signature_help";
                priority = 1000;
                # group_index = 2;
                option = {
                  inherit get_bufnrs;
                };
              }
              {
                name = "nvim_lsp_document_symbol";
                priority = 1000;
                # group_index = 2;
                option = {
                  inherit get_bufnrs;
                };
              }
              {
                name = "treesitter";
                priority = 850;
                option = {
                  inherit get_bufnrs;
                };
              }
              {
                name = "luasnip";
                priority = 750;
              }
              {
                name = "buffer";
                priority = 500;
                option = {
                  inherit get_bufnrs;
                };
              }
              {
                name = "async_path";
                priority = 400;
              }
              {
                name = "cmdline";
                priority = 300;
              }
              {
                name = "git";
                priority = 250;
              }
              # {
              #   name = "fish";
              #   priority = 200;
              # }
              # {
              #   name = "zsh";
              #   priority = 250;
              # }
              {
                name = "calc";
                priority = 150;
              }
              {
                name = "emoji";
                priority = 100;
              }
            ];

            window = {
              completion.__raw = ''cmp.config.window.bordered()'';
              documentation.__raw = ''cmp.config.window.bordered()'';
            };
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf (cfg.copilot-cmp.enable && copilot-lua-check) {
      plugins.copilot-lua = {
        suggestion.enabled = mkOverrideAtNixvimProfileLevel false;
        panel.enabled = mkOverrideAtNixvimProfileLevel false;
      };

      plugins.cmp.settings = {
        sources = [
          {
            name = "copilot";
            priority = 1200;
            # group_index = 2;
            option = {
              inherit get_bufnrs;
            };
          }
        ];
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
