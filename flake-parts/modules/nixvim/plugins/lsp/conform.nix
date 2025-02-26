# --- flake-parts/modules/nixvim/plugins/lsp/conform.nix
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

  cfg = config.tensorfiles.nixvim.plugins.lsp.conform;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.lsp.conform = {
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
      plugins.conform-nvim = {
        enable = _ true;
        settings = {
          # format_on_save = ''
          #   function(bufnr)
          #     if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          #       return
          #     end
          #
          #     if slow_format_filetypes[vim.bo[bufnr].filetype] then
          #       return
          #     end
          #
          #     local function on_format(err)
          #       if err and err:match("timeout$") then
          #         slow_format_filetypes[vim.bo[bufnr].filetype] = true
          #       end
          #     end
          #
          #     return { timeout_ms = 200, lsp_fallback = true }, on_format
          #    end
          # '';
          format_after_save = ''
            function(bufnr)
              if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
              end

              if not slow_format_filetypes[vim.bo[bufnr].filetype] then
                return
              end

              return { lsp_fallback = true }
            end
          '';
          notify_on_error = _ true;
          notify_no_formatters = _ true;
          formatters_by_ft = {
            html = [
              [
                "prettierd"
                "prettier"
              ]
            ];
            css = [
              [
                "prettierd"
                "prettier"
              ]
            ];
            javascript = [
              [
                "prettierd"
                "prettier"
              ]
            ];
            typescript = [
              [
                "prettierd"
                "prettier"
              ]
            ];
            python = [
              "black"
              "isort"
            ];
            lua = [ "stylua" ];
            nix = [ "nixfmt-rfc-style" ];
            markdown = [
              [
                "prettierd"
                "prettier"
              ]
            ];
            yaml = [
              [
                "prettierd"
                "prettier"
              ]
            ];
            terraform = [ "terraform_fmt" ];
            bicep = [ "bicep" ];
            bash = [
              "shellcheck"
              "shellharden"
              "shfmt"
            ];
            json = [ "jq" ];
            "_" = [ "trim_whitespace" ];
          };

          formatters = {
            black = {
              command = _ "${lib.getExe pkgs.black}";
            };
            isort = {
              command = _ "${lib.getExe pkgs.isort}";
            };
            alejandra = {
              command = _ "${lib.getExe pkgs.alejandra}";
            };
            nixfmt-rfc-style = {
              command = _ "${lib.getExe pkgs.nixfmt-rfc-style}";
            };
            jq = {
              command = _ "${lib.getExe pkgs.jq}";
            };
            prettierd = {
              command = _ "${lib.getExe pkgs.prettierd}";
            };
            stylua = {
              command = _ "${lib.getExe pkgs.stylua}";
            };
            shellcheck = {
              command = _ "${lib.getExe pkgs.shellcheck}";
            };
            shfmt = {
              command = _ "${lib.getExe pkgs.shfmt}";
            };
            shellharden = {
              command = _ "${lib.getExe pkgs.shellharden}";
            };
            bicep = {
              command = _ "${lib.getExe pkgs.bicep}";
            };
            #yamlfmt = {
            #  command = _ "${lib.getExe pkgs.yamlfmt}";
            #};
          };
        };
      };

      extraConfigLuaPre = ''
        local slow_format_filetypes = {}

        vim.api.nvim_create_user_command("FormatDisable", function(args)
           if args.bang then
            -- FormatDisable! will disable formatting just for this buffer
            vim.b.disable_autoformat = true
          else
            vim.g.disable_autoformat = true
          end
        end, {
          desc = "Disable autoformat-on-save",
          bang = true,
        })
        vim.api.nvim_create_user_command("FormatEnable", function()
          vim.b.disable_autoformat = false
          vim.g.disable_autoformat = false
        end, {
          desc = "Re-enable autoformat-on-save",
        })
        vim.api.nvim_create_user_command("FormatToggle", function(args)
          if args.bang then
            -- Toggle formatting for current buffer
            vim.b.disable_autoformat = not vim.b.disable_autoformat
          else
            -- Toggle formatting globally
            vim.g.disable_autoformat = not vim.g.disable_autoformat
          end
        end, {
          desc = "Toggle autoformat-on-save",
          bang = true,
        })
      '';
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.withKeymaps {
      keymaps = [
        {
          mode = "n";
          key = "<leader>cf";
          action = "<cmd>Format<CR>";
          options = {
            silent = true;
            desc = "Conform formatter.";
          };
        }
      ];
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
