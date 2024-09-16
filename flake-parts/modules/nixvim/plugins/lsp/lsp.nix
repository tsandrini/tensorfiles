# --- flake-parts/modules/nixvim/plugins/lsp/lsp.nix
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
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel;

  cfg = config.tensorfiles.nixvim.plugins.lsp.lsp;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.lsp.lsp = {
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
      extraPlugins = with pkgs.vimPlugins; [
        ansible-vim
      ];

      plugins = {
        lsp-lines = {
          enable = _ true;
        };

        lsp-format = {
          enable = _ true;
        };

        lsp = {
          enable = _ true;
          inlayHints = _ true;
          servers = {
            ansiblels.enable = _ true;
            astro.enable = _ true;
            bashls.enable = _ true;
            hls.enable = _ true;
            biome.enable = _ true;
            clangd.enable = _ true;
            cssls.enable = _ true;
            docker-compose-language-service.enable = _ true;
            dockerls.enable = _ true;
            graphql.enable = _ true;
            html.enable = _ true;
            # intelephense.enable = _ true; # NOTE unfree
            jsonls.enable = _ true;
            lua-ls.enable = _ true;
            nginx-language-server.enable = _ true;
            nil-ls.enable = _ true;
            ocamllsp.enable = _ true;
            pyright.enable = _ true;
            sqls.enable = _ true;
            terraformls.enable = _ true;
            tsserver.enable = _ true;
            rust-analyzer = {
              enable = _ true;
              installCargo = _ false; # TODO
              installRustc = _ false; # TODO
            };
            yamlls = {
              enable = _ true;
              extraOptions = {
                settings = {
                  yaml = {
                    schemas = {
                      kubernetes = _ "'*.yaml";
                      "http://json.schemastore.org/github-workflow" = _ ".github/workflows/*";
                      "http://json.schemastore.org/github-action" = _ ".github/action.{yml,yaml}";
                      "http://json.schemastore.org/ansible-stable-2.9" = _ "roles/tasks/*.{yml,yaml}";
                      "http://json.schemastore.org/kustomization" = _ "kustomization.{yml,yaml}";
                      "http://json.schemastore.org/ansible-playbook" = _ "*play*.{yml,yaml}";
                      "http://json.schemastore.org/chart" = _ "Chart.{yml,yaml}";
                      "https://json.schemastore.org/dependabot-v2" = _ ".github/dependabot.{yml,yaml}";
                      "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" = _ "*docker-compose*.{yml,yaml}";
                      "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" = _ "*flow*.{yml,yaml}";
                    };
                  };
                };
              };
            };
          };
        };
      };

      # extraConfigLua = ''
      #   local _border = "rounded"
      #
      #   vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
      #     vim.lsp.handlers.hover, {
      #       border = _border
      #     }
      #   )
      #
      #   vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
      #     vim.lsp.handlers.signature_help, {
      #       border = _border
      #     }
      #   )
      #
      #   vim.diagnostic.config{
      #     float={border=_border}
      #   };
      #
      #   require('lspconfig.ui.windows').default_options = {
      #     border = _border
      #   }
      # '';
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.withKeymaps {
      plugins.lsp.keymaps = {
        silent = _ true;
        lspBuf = {
          gd = {
            action = "definition";
            desc = "Goto Definition";
          };
          "<leader>ca" = {
            action = "code_action";
            desc = "Code action";
          };
          "<leader>cd" = {
            action = "definition";
            desc = "Goto Definition";
          };
          gr = {
            action = "references";
            desc = "Goto References";
          };
          "<leader>cR" = {
            action = "references";
            desc = "Goto References";
          };
          gD = {
            action = "declaration";
            desc = "Goto Declaration";
          };
          "<leader>cD" = {
            action = "declaration";
            desc = "Goto Declaration";
          };
          gI = {
            action = "implementation";
            desc = "Goto Implementation";
          };
          "<leader>ci" = {
            action = "implementation";
            desc = "Goto Implementation";
          };
          gT = {
            action = "type_definition";
            desc = "Type Definition";
          };
          "<leader>ct" = {
            action = "type_definition";
            desc = "Type Definition";
          };
          "<C-k>" = {
            action = "hover";
            desc = "Hover";
          };
          "<leader>cw" = {
            action = "workspace_symbol";
            desc = "Workspace Symbol";
          };
          # "<leader>cf" = {
          #   action = "format";
          #   desc = "LSP format";
          # };
        };
        # diagnostic = {
        #   "<leader>cx" = {
        #     action = "open_float";
        #     desc = "Line Diagnostics";
        #   };
        #   "[d" = {
        #     action = "goto_next";
        #     desc = "Next Diagnostic";
        #   };
        #   "]d" = {
        #     action = "goto_prev";
        #     desc = "Previous Diagnostic";
        #   };
        # };
      };
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
