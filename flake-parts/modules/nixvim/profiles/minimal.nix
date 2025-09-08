# --- flake-parts/modules/nixvim/profiles/minimal.nix
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
          editor.buffer-manager.enable = _ true;
          editor.spectre.enable = _ true;
          editor.render-markdown.enable = _ true;
          editor.nvim-ufo.enable = _ true;
          editor.indent-blankline.enable = _ true;
        };
      };

      plugins.colorizer.enable = _ true;

      extraPlugins = with pkgs.vimPlugins; [
        # nightfox-nvim
        vscode-nvim
        bamboo-nvim
        # bluloco-nvim # NOTE brokey
        boo-colorscheme-nvim
        catppuccin-nvim
        citruszest-nvim
        cyberdream-nvim
        doom-one-nvim
        dracula-nvim
        everforest
        gruvbox-nvim
        gruvbox-material-nvim
        kanagawa-nvim
        melange-nvim
        miasma-nvim
        modus-themes-nvim
        monokai-pro-nvim
        neovim-ayu
        nord-nvim
        nordic-nvim
        github-nvim-theme
        # omni-nvim
        # one-nvim # NOTE brokey
        onedark-nvim
        onenord-nvim
        oxocarbon-nvim
        palette-nvim
        # poimandres-nvim
        rose-pine
        substrata-nvim
        tokyonight-nvim
        # zenbones-nvim # NOTE brokey
        zephyr-nvim
      ];

      plugins.mini = {
        enable = _ true;
        mockDevIcons = _ true;
        modules = {
          ai = { };
          icons = { };
          # indentscope = { };
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
