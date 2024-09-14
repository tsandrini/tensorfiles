# --- flake-parts/modules/nixvim/default.nix
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
{
  lib,
  self,
  inputs,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (inputs.flake-parts.lib) importApply;
  localFlake = self;
in
{
  options.flake.nixvimModules = mkOption {
    type = types.lazyAttrsOf types.unspecified;
    default = { };
  };

  config.flake.nixvimModules = {
    auto_cmds = importApply ./auto_cmds.nix { inherit localFlake; };
    keymaps = importApply ./keymaps.nix { inherit localFlake; };
    neovide = importApply ./neovide.nix { inherit localFlake; };
    settings = importApply ./settings.nix { inherit localFlake; };

    profiles_base = importApply ./profiles/base.nix { inherit localFlake; };
    profiles_minimal = importApply ./profiles/minimal.nix { inherit localFlake; };
    profiles_graphical = importApply ./profiles/graphical.nix { inherit localFlake; };
    profiles_ide = importApply ./profiles/ide.nix { inherit localFlake; };

    plugins_git_neogit = importApply ./plugins/git/neogit.nix { inherit localFlake; };

    plugins_utils_hop = importApply ./plugins/utils/hop.nix { inherit localFlake; };
    plugins_utils_faster = importApply ./plugins/utils/faster.nix { inherit localFlake; };
    plugins_utils_orgmode = importApply ./plugins/utils/orgmode.nix { inherit localFlake; };
    plugins_utils_project-nvim = importApply ./plugins/utils/project-nvim.nix { inherit localFlake; };
    plugins_utils_telescope = importApply ./plugins/utils/telescope.nix { inherit localFlake; };
    plugins_utils_which-key = importApply ./plugins/utils/which-key.nix { inherit localFlake; };
    plugins_utils_markdown-preview = importApply ./plugins/utils/markdown-preview.nix {
      inherit localFlake;
    };

    plugins_editor_bufferline = importApply ./plugins/editor/bufferline.nix { inherit localFlake; };
    plugins_editor_spectre = importApply ./plugins/editor/spectre.nix { inherit localFlake; };
    plugins_editor_copilot-lua = importApply ./plugins/editor/copilot-lua.nix { inherit localFlake; };
    plugins_editor_neo-tree = importApply ./plugins/editor/neo-tree.nix { inherit localFlake; };
    plugins_editor_noice = importApply ./plugins/editor/noice.nix { inherit localFlake; };
    plugins_editor_treesitter = importApply ./plugins/editor/treesitter.nix { inherit localFlake; };
    plugins_editor_undotree = importApply ./plugins/editor/undotree.nix { inherit localFlake; };
    plugins_editor_render-markdown = importApply ./plugins/editor/render-markdown.nix {
      inherit localFlake;
    };

    plugins_cmp_cmp = importApply ./plugins/cmp/cmp.nix { inherit localFlake; };
    plugins_cmp_lspkind = importApply ./plugins/cmp/lspkind.nix { inherit localFlake; };
    plugins_cmp_schemastore = importApply ./plugins/cmp/schemastore.nix { inherit localFlake; };

    plugins_lsp_conform = importApply ./plugins/lsp/conform.nix { inherit localFlake; };
    plugins_lsp_fidget = importApply ./plugins/lsp/fidget.nix { inherit localFlake; };
    plugins_lsp_lsp = importApply ./plugins/lsp/lsp.nix { inherit localFlake; };
    plugins_lsp_lspsaga = importApply ./plugins/lsp/lspsaga.nix { inherit localFlake; };
    plugins_lsp_trouble = importApply ./plugins/lsp/trouble.nix { inherit localFlake; };
    plugins_lsp_otter = importApply ./plugins/lsp/otter.nix { inherit localFlake; };
  };
}
