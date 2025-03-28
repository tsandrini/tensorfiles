# --- flake-parts/modules/nixvim/plugins/utils/markdown-preview.nix
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

  cfg = config.tensorfiles.nixvim.plugins.utils.markdown-preview;
  _ = mkOverrideAtNixvimModuleLevel;
in
{
  options.tensorfiles.nixvim.plugins.utils.markdown-preview = {
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
        markdown-preview = {
          enable = _ true;
          settings = {
            browser = _ "firefox";
            echo_preview_url = _ 1;
            port = _ "6969";
            preview_options = {
              disable_filename = _ 1;
              disable_sync_scroll = _ 1;
              sync_scroll_type = _ "middle";
            };
            theme = _ "dark";
          };
        };
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.withKeymaps {
      keymaps = [
        {
          mode = "n";
          key = "<leader>mp";
          action = "<cmd>MarkdownPreview<cr>";
          options = {
            desc = "Toggle Markdown Preview";
          };
        }
      ];
    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
