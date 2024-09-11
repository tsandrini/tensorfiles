# --- flake-parts/modules/home-manager/programs/editors/neovim.nix
#
# Author:  tsandrini <tomas.sandrini@seznam.cz>
# URL:     https://github.com/tsandrini/tensorfiles.hm
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
  system,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    optional
    mkEnableOption
    ;
  inherit (localFlake.lib.modules)
    mkOverrideAtHmModuleLevel
    mkDummyDerivation
    isModuleLoadedAndEnabled
    ;
  inherit (localFlake.lib.options) mkPywalEnableOption;

  cfg = config.tensorfiles.hm.programs.editors.neovim;
  _ = mkOverrideAtHmModuleLevel;

  pywalCheck = (isModuleLoadedAndEnabled config "tensorfiles.hm.programs.pywal") && cfg.pywal.enable;
in
{
  # TODO modularize config, cant be bothered to do it now
  options.tensorfiles.hm.programs.editors.neovim = {
    enable = mkEnableOption ''
      Enables NixOS module that configures/handles the neovim program.
    '';

    pywal = {
      enable = mkPywalEnableOption;
    };

    vscode = {
      enable = mkEnableOption ''
        Adds support for the vscode-neovim plugin.
      '';
    };

    lsp = {
      enable = mkEnableOption ''
        Enables LSP support for neovim.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # |----------------------------------------------------------------------| #
    {
      home.shellAliases = {
        "neovim" = _ "nvim";
      };
      programs.neovim = {
        enable = _ true;
        viAlias = _ true;
        vimAlias = _ true;
        # error: The option `programs.neovim.withPython' can no longer be used
        # since it's been removed. Python2 support has been removed from neovim
        # withPython3 = _ true;
        withNodeJs = _ true;
        plugins =
          with pkgs.vimPlugins;
          (
            # NOTE programs.neovim.extraConfig uses vimscript, which is why
            # we setup the configuration using plugins where we can specify
            # lua instead
            [
              {
                plugin = mkDummyDerivation {
                  inherit (pkgs) stdenv;
                  name = "neovim-base-config";
                  meta.system = system;
                };
                type = "lua";
                config = ''
                  -- Set options
                  vim.opt.number = true
                  vim.opt.relativenumber = true

                  vim.opt.formatoptions:append('l')
                  vim.opt.rulerformat = '%l:%c'
                  vim.opt.foldenable = false

                  vim.opt.wildmenu = true
                  vim.opt.wildmode = 'full'
                  vim.opt.wildignorecase = true
                  vim.opt.clipboard:append('unnamedplus')

                  vim.opt.tabstop = 8
                  vim.opt.softtabstop = 0
                  vim.opt.expandtab = true
                  vim.opt.shiftwidth = 4
                  vim.opt.smarttab = true

                  vim.opt.scrolloff = 5

                  vim.opt.list = true
                  vim.opt.listchars = {tab = '»·', trail = '•', extends = '#', nbsp = '.'}

                  vim.cmd('filetype indent on')
                  vim.opt.smartindent = true
                  vim.opt.shiftround = true

                  vim.opt.ignorecase = true
                  vim.opt.smartcase = true
                  vim.opt.showmatch = true

                  -- Auto-remove trailing whitespace
                  vim.api.nvim_create_autocmd('BufWritePre', {
                      pattern = '*',
                      command = [[%s/\s\+$//e]]
                  })

                  -- Set leaders
                  vim.g.mapleader = ' '
                  vim.g.maplocalleader = ' '

                  -- Key mappings
                  local function map(mode, lhs, rhs, opts)
                      local options = {noremap = true, silent = true}
                      if opts then options = vim.tbl_extend('force', options, opts) end
                      vim.api.nvim_set_keymap(mode, lhs, rhs, options)
                  end

                  map('i', 'jk', '<Esc>')
                  map('i', 'kj', '<Esc>')
                  map('c', 'jk', '<C-c>')
                  map('c', 'kj', '<C-c>')
                  map('t', 'jk', '<C-\\><C-n>')
                  map('t', 'kj', '<C-\\><C-n>')
                  -- map('v', 'jk', '<Esc>')
                  -- map('v', 'kj', '<Esc>')

                  map('n', 'J', ':tabprevious<CR>')
                  map('n', 'K', ':tabnext<CR>')
                '';
              }
            ]
            ++ (optional pywalCheck {
              plugin = pywal-nvim;
              type = "lua";
              config = ''
                require('pywal').setup()
              '';
            })
            ++ [
              mini-nvim
              transparent-nvim
              vim-repeat
              # nnn-vim
              vim-fugitive
              popup-nvim
              plenary-nvim
              nvim-web-devicons
              bufexplorer
              undotree
              {
                plugin = dressing-nvim;
                type = "lua";
                config = ''
                  require('dressing').setup{}
                '';
              }
              # lexima-vim # use nvim-autopairs instead
              {
                plugin = nvim-autopairs;
                type = "lua";
                config = ''
                  require('nvim-autopairs').setup{}
                '';
              }
              {
                plugin = trouble-nvim;
                type = "lua";
                config = ''
                  require('trouble').setup{}
                '';
              }
              {
                plugin = comment-nvim;
                type = "lua";
                config = ''
                  require('Comment').setup{}
                '';
              }
              {
                plugin = todo-comments-nvim;
                type = "lua";
                config = ''
                  require('todo-comments').setup{}
                '';
              }
              # vim-vsnip-integ
              # friendly-snippets
              {
                plugin = indent-blankline-nvim;
                type = "lua";
                config = ''
                  require('ibl').setup{}
                '';
              }
              # {
              #   plugin = indentLine;
              #   type = "lua";
              #   config = ''
              #     vim.g.indentLine_char = '┆'
              #     vim.g.indentLine_color_term = 239
              #   '';
              # }
              # {
              #   plugin = vim-vsnip;
              #   type = "lua";
              #   config = "";
              # }
              {
                plugin = vim-move;
                type = "lua";
                config = ''
                  vim.g.move_key_modifier = "C"
                '';
              }
              {
                plugin = vim-suda;
                type = "lua";
                config = "";
              }
              {
                plugin = telescope-nvim;
                type = "lua";
                config = ''
                  require('telescope').setup{
                    defaults = {
                      prompt_prefix = "🔍"
                    }
                  }
                '';
              }
              {
                plugin = hop-nvim;
                type = "lua";
                config = ''
                  require('hop').setup{ keys = 'asdfghjkl' }

                  vim.keymap.set("n", ",", "<cmd>HopChar2<CR>", {})
                '';
              }
              {
                plugin = lualine-nvim;
                type = "lua";
                config = ''
                  require('lualine').setup{
                    options = {
                      ${if pywalCheck then "theme = 'pywal-nvim'," else ""}
                      icons_enabled = true
                    },
                    sections = {
                      lualine_a = {{"mode", upper=true}},
                      lualine_b = {{"branch", icon=""}},
                      lualine_c = {{"filename", file_status=true}},
                      lualine_x = {"encoding", "fileformat", "filetype"},
                      lualine_y = {"progress"},
                      lualine_z = {"location"},
                    }
                  }
                '';
              }
              {
                plugin = vim-fern;
                type = "lua";
                config = ''
                  vim.g.loaded_netrw = false
                  vim.g.loaded_netrwPlugin = false
                  vim.g.loaded_netrwSettings = false
                  vim.g.loaded_netrwFileHandlers = false

                  -- vim.g["fern#renderer"] = "nerdfont" TODO
                  vim.g["fern#disable_default_mappings"] = true

                  vim.api.nvim_set_keymap(
                    "n",
                    "m",
                    ":Fern . -drawer -reveal=% -width=35 <CR><C-w>=",
                    {noremap=true, silent=true}
                  )

                  vim.api.nvim_set_keymap(
                    "n",
                    "<Plug>(fern-close-drawer)",
                    ":<C-u>FernDo close -drawer -stay<CR>",
                    {noremap=true, silent=true}
                  )

                  local function fern_init()
                    local opts = {silent=true}
                    vim.api.nvim_set_keymap("n", "<Plug>(fern-action-open)",
                      "<Plug>(fern-action-open:select)", opts)

                    vim.api.nvim_buf_set_keymap(
                      0,
                      "n",
                      "<Plug>(fern-action-custom-open-expand-collapse)",
                      "fern#smart#leaf('<plug>(fern-action-open)<plug>(fern-close-drawer)', '<plug>(fern-action-expand)', '<plug>(fern-action-collapse)')",
                      {silent=true, expr=true}
                    )
                    vim.api.nvim_buf_set_keymap(0, "n", "q", ":<C-u>quit<CR>", opts)
                    vim.api.nvim_buf_set_keymap(0, "n", "n", "<Plug>(fern-action-new-path)", opts)
                    vim.api.nvim_buf_set_keymap(0, "n", "d", "<Plug>(fern-action-remove)", opts)
                    vim.api.nvim_buf_set_keymap(0, "n", "m", "<Plug>(fern-action-move)", opts)
                    vim.api.nvim_buf_set_keymap(0, "n", "r", "<Plug>(fern-action-rename)", opts)
                    vim.api.nvim_buf_set_keymap(0, "n", "R", "<Plug>(fern-action-reload)", opts)
                    vim.api.nvim_buf_set_keymap(0, "n", "<C-h>", "<Plug>(fern-action-hidden-toggle)", opts)
                    vim.api.nvim_buf_set_keymap(0, "n", "l", "<Plug>(fern-action-custom-open-expand-collapse)", opts)
                    vim.api.nvim_buf_set_keymap(0, "n", "h", "<Plug>(fern-action-collapse)", opts)
                    vim.api.nvim_buf_set_keymap(0, "n", "<2-LeftMouse>", "<Plug>(fern-action-custom-open-expand-collapse)", opts)
                    vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "<Plug>(fern-action-custom-open-expand-collapse)", opts)
                  end

                  local group = vim.api.nvim_create_augroup("fern_group", {clear=true})
                  vim.api.nvim_create_autocmd("FileType", {
                    pattern="fern",
                    callback=fern_init,
                    group=group
                  })
                '';
              }
              {
                plugin = which-key-nvim;
                type = "lua";
                config = ''
                  -- vim.api.nvim_set_option("timeoutlen", 500)

                  require("which-key").setup{
                    preset = "modern",
                    delay = 100
                  }

                  require("which-key").add({
                    { "<leader>", group = "+general" },
                    { "<leader>/", ":Telescope live_grep<CR>", desc = "Telescope grep" },
                    { "<leader><leader>", ":Telescope find_files<CR>", desc = "Find files" },
                    { "<leader>Q", ":qall<CR>", desc = "Quit all files" },
                    { "<leader>b", group = "+bufexplorer" },
                    { "<leader>bi", "<cmd>BufExplorer<CR>", desc = "Open BufExplorer" },
                    { "<leader>bs", "<cmd>BufExplorerHorizontalSplit<CR>", desc = "BufExplorer horizontal split" },
                    { "<leader>bt", "<cmd>ToggleBufExplorer<CR>", desc = "Toggle BufExplorer" },
                    { "<leader>bv", "<cmd>BufExplorerVerticalSplit<CR>", desc = "BufExplorer vertical split" },
                    { "<leader>g", group = "+git" },
                    { "<leader>ga", ":Git add *<CR>", desc = "Git add all" },
                    { "<leader>gb", ":Git blame<CR>", desc = "Git blame" },
                    { "<leader>gc", ":Git commit --verbose<CR>", desc = "Git commit (verbose)" },
                    { "<leader>gd", ":Gdiff<CR>", desc = "Git diff" },
                    { "<leader>ge", ":GitMessenger<CR>", desc = "Git messenger" },
                    { "<leader>gf", ":Git fetch<CR>", desc = "Git fetch" },
                    { "<leader>gl", ":Git pull<CR>", desc = "Git pull" },
                    { "<leader>gp", ":Git push<CR>", desc = "Git push" },
                    { "<leader>gs", ":Git<CR>", desc = "Git status" },
                    { "<leader>h", "<C-w>h", desc = "Window left" },
                    { "<leader>j", "<C-w>j", desc = "Window below" },
                    { "<leader>k", "<C-w>k", desc = "Window above" },
                    { "<leader>l", "<C-w>l", desc = "Window right" },
                    { "<leader>n", ":tabnew<CR>", desc = "New tab" },
                    { "<leader>p", group = "+telescope" },
                    { "<leader>pb", ":Telescope buffers<CR>", desc = "Buffers" },
                    { "<leader>pc", ":Telescope git_commits<CR>", desc = "Git commits" },
                    { "<leader>pf", ":Telescope find_files<CR>", desc = "Find files" },
                    { "<leader>pg", ":Telescope git_files<CR>", desc = "Git files" },
                    { "<leader>ph", ":Telescope man_pages<CR>", desc = "Man pages" },
                    { "<leader>pl", ":Telescope colorscheme<CR>", desc = "Colorschemes" },
                    { "<leader>pm", ":Telescope commands<CR>", desc = "Commands" },
                    { "<leader>pr", ":Telescope live_grep<CR>", desc = "Live grep" },
                    { "<leader>ps", ":Telescope snippets<CR>", desc = "Snippets" },
                    { "<leader>q", ":q<CR>", desc = "Quit file" },
                    { "<leader>r", ":noh<CR>", desc = "Remove highlights" },
                    { "<leader>s", "<C-w>s", desc = "Split window below" },
                    { "<leader>t", ":terminal<CR>", desc = "Open terminal" },
                    { "<leader>u", ":UndotreeToggle<CR>", desc = "Toggle Undotree" },
                    { "<leader>v", "<C-w>v", desc = "Split window right" },
                    { "<leader>w", ":w<CR>", desc = "Save file" }
                  })
                '';
              }
              # {
              #   plugin = vim-easymotion;
              #   type = "lua";
              #   config = ''
              #     vim.g.EasyMotion_do_mapping = false
              #     vim.g.EasyMotion_smartcase = true

              #     vim.keymap.set("n", ",", "<Plug>(easymotion-overwin-f2)", {})
              #   '';
              # }
              # NOTE slows things down too much and I am also mostly using
              # only hop.nvim
              # {
              #   plugin = quick-scope;
              #   type = "lua";
              #   config = '''';
              # }
              # (pkgs.vimUtils.buildVimPlugin {
              #   pname = "kitty-scrollback.nvim";
              #   version = inputs.kitty-scrollback-nvim.rev;
              #   src = inputs.kitty-scrollback-nvim;
              # })
            ]
          );
      };
    }
    # |----------------------------------------------------------------------| #
    (mkIf cfg.vscode.enable {
      programs.neovim.plugins = [
        {

          plugin = pkgs.vimPlugins.vscode-neovim;
          type = "lua";
          config = ''
            if exists('g:vscode')
              set noloadplugins
              set clipboard^=unnamed,unnamedplus

              finish
            endif
          '';
        }
      ];
    })
    # |----------------------------------------------------------------------| #
    (mkIf cfg.lsp.enable {
      programs.neovim = {
        # TODO
        extraPackages = with pkgs; [ ];

        plugins = with pkgs.vimPlugins; [
          {
            plugin = fidget-nvim;
            type = "lua";
            config = ''
              require('fidget').setup{}
            '';
          }
          {
            plugin = nvim-lspconfig;
            type = "lua";
            config = ''
              local lspconfig = require('lspconfig')

              lspconfig.pyright.setup{}
              lspconfig.nil_ls.setup{}
              lspconfig.biome.setup{}
              lspconfig.clangd.setup{}
              lspconfig.cmake.setup{}
              lspconfig.tsserver.setup{}
              lspconfig.css_variables.setup{}
              lspconfig.dockerls.setup{}
              lspconfig.fish_lsp.setup{}
              lspconfig.giltab_ci.setup{}
              lspconfig.html.setup{}
              lspconfig.julials.setup{}
              lspconfig.lua_ls.setup{}
              lspconfig.ols.setup{}
              lspconfig.sqlls.setup{}
              lspconfig.docker_compose_language_service.setup{}
              lspconfig.vimls.setup{}
              lspconfig.yamlls.setup{}
              lspconfig.rust_analyzer.setup{}
            '';
          }
          {
            plugin = nvim-treesitter.withAllGrammars;
            type = "lua";
            config = ''
              require('nvim-treesitter.configs').setup{
                sync_install = false,
                auto_install = false,
                highlight = {
                  enable = true,
                  disable = { "latex" }
                },
                incremental_selection = {
                  enable = true
                },
                indent = {
                  enable = true
                }
              };
            '';
          }
          {
            plugin = copilot-lua;
            type = "lua";
            config = ''
              require('copilot').setup{
                suggestion = {
                  auto_trigger = true
                }
              }
            '';
          }
          {
            plugin = render-markdown;
            type = "lua";
            config = ''
              require('render-markdown').setup{}
            '';
          }
          {
            plugin = formatter-nvim;
            type = "lua";
            config = ''
              require('formatter')

              local augroup = vim.api.nvim_create_augroup
              local autocmd = vim.api.nvim_create_autocmd
              augroup("__formatter__", { clear = true })
              autocmd("BufWritePost", {
              	group = "__formatter__",
              	command = ":FormatWrite",
              })

              require("which-key").add({
                { "<leader>f", ":Format<CR>", desc = "Format file" },
              })
            '';
          }
          {
            plugin = nvim-lint;
            type = "lua";
            config = "";
          }
        ];
      };

    })
    # |----------------------------------------------------------------------| #
  ]);

  meta.maintainers = with localFlake.lib.maintainers; [ tsandrini ];
}
