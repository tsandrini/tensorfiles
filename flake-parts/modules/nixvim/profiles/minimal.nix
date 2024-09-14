# --- flake-parts/modules/nixvim/profiles/minimal.nix
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
  inherit (localFlake.lib.modules) mkOverrideAtNixvimProfileLevel;

  cfg = config.tensorfiles.nixvim.profiles.minimal;
  _ = mkOverrideAtNixvimProfileLevel;
in
{
  options.tensorfiles.nixvim.profiles.minimal = {
    enable = mkEnableOption ''
      TODO
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      tensorfiles.nixvim = {
        profiles.base.enable = _ true;

        plugins = {
          utils.telescope.enable = _ true;
          utils.hop.enable = _ true;
          utils.faster.enable = _ true;
          utils.which-key.enable = _ true;
          utils.orgmode.enable = _ true;
          utils.project-nvim.enable = _ true;

          git.neogit.enable = _ true;

          editor.neo-tree.enable = _ true;
          editor.treesitter.enable = _ true;
          editor.undotree.enable = _ true;
          editor.bufferline.enable = _ true;
          editor.spectre.enable = _ true;
          editor.render-markdown.enable = _ true;
        };
      };

      plugins.nvim-colorizer.enable = _ true;

      extraPlugins = with pkgs.vimPlugins; [
        # nightfox-nvim
        catppuccin-nvim
        cyberdream-nvim
        gruvbox-nvim
        kanagawa-nvim
        modus-themes-nvim
        neovim-ayu
        onedark-nvim
        oxocarbon-nvim
        rose-pine
        tokyonight-nvim
        # vscode-nvim
      ];

      plugins.mini = {
        enable = _ true;
        modules = {
          ai = { };
          icons = { };
          indentscope = { };
          pairs = { };
          # tabline = { }; # TODO I hate how it shows all buffers
          cursorword = { };
          comment = { };
          move = {
            mappings = {
              left = "<C-h>";
              right = "<C-l>";
              down = "<C-j>";
              up = "<C-k>";
            };
          };
          hipatterns = {
            highlighters = {
              fixme = {
                pattern = "%f[%w]()FIXME()%f[%W]";
                group = "MiniHipatternsFixme";
              };
              hack = {
                pattern = "%f[%w]()HACK()%f[%W]";
                group = "MiniHipatternsHack";
              };
              todo = {
                pattern = "%f[%w]()TODO()%f[%W]";
                group = "MiniHipatternsTodo";
              };
              note = {
                pattern = "%f[%w]()NOTE()%f[%W]";
                group = "MiniHipatternsNote";
              };
            };
          };

          # Stuff needed for statusline
          statusline = { };
          git = { };
          diff = { };
        };
      };
    }
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
