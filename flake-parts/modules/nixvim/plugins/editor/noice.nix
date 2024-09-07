# --- flake-parts/modules/nixvim/plugins/editor/noice.nix
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
    ;
  inherit (localFlake.lib.modules) mkOverrideAtNixvimModuleLevel;

  cfg = config.tensorfiles.nixvim.plugins.editor.noice;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.editor.noice = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      plugins.notify.enable = _ true;

      plugins.noice = {
        enable = _ true;
        lsp = {
          override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = _ true;
            "vim.lsp.util.stylize_markdown" = _ true;
            "cmp.entry.get_documentation" = _ true;
          };
          hover.enabled = _ false;
          message.enabled = _ false;
          signature.enabled = _ false;
          progress.enabled = _ false;
        };
        presets = {
          bottom_search = _ true;
          command_palette = _ true;
          long_message_to_split = _ true;
          inc_rename = _ false;
          lsp_doc_border = _ false;
        };
      };

      extraConfigLua = ''
        require('notify').setup({
          split = true,
          background_colour = "#000000",
          render = "compact",
          stages = "fade_in_slide_out",
          top_down = false,
        })
      '';

      # keymaps = [
      #   (mkKeymap "n" "<leader>un" {
      #     __raw = "function () require('notify').dismiss() end";
      #   } "Dismiss notification")
      # ];
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
