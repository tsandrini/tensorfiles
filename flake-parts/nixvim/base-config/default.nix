# --- flake-parts/nixvim/base-config/default.nix
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
_:
{ lib, pkgs, ... }:
let
  _ = lib.mkOverride 500;
in
{
  imports = [ ];

  tensorfiles.nixvim = {
    settings.enable = true;
    keymaps.enable = true;
    auto_cmds.enable = true;

    neovide.enable = true;

    plugins = {
      utils.telescope.enable = true;
      utils.hop.enable = true;
      utils.orgmode.enable = true;
      utils.which-key.enable = true;
      utils.markdown-preview.enable = true;
      utils.project-nvim.enable = true;

      editor.neo-tree.enable = true;
      editor.undotree.enable = true;
      editor.bufferline.enable = true;
      editor.treesitter.enable = true;
      # TODO [Copilot] Could not find agent.js (bad install?) : nil
      editor.copilot-lua.enable = true;

      git.neogit.enable = true;

      cmp.cmp.enable = true;
      cmp.lspkind.enable = true;
      cmp.schemastore.enable = true;

      lsp.lsp.enable = true;
      lsp.conform.enable = true;
      lsp.fidget.enable = true;
      lsp.trouble.enable = true;
    };
  };

  colorschemes.nightfox.enable = true;

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

  plugins.direnv.enable = _ true;
  plugins.nvim-colorizer.enable = _ true;

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


  performance = {
    combinePlugins.enable = true;
    byteCompileLua.enable = true;
  };
}
