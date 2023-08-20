# --- profiles/neovim.nix
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
{ config, pkgs, lib, inputs, user, ... }:
let _ = lib.mkOverride 500;
in {
  environment.variables = {
    EDITOR = _ "nvim";
    VISUAL = _ "nvim";
  };

  home-manager.users.${user} = {
    programs.neovim = {
      enable = _ true;
      viAlias = _ true;
      vimAlias = _ true;
      withPython3 = _ true;
      withNodeJs = _ true;
      extraConfig = ''
        set number
        set relativenumber

        set formatoptions+=l
        set rulerformat=%l:%c
        set nofoldenable

        set wildmenu
        set wildmode=full"
        set wildignorecase

        set tabstop=8
        set softtabstop=0
        set expandtab
        set shiftwidth=4
        set smarttab

        set scrolloff=5

        set list
        set listchars=tab:»·,trail:•,extends:#,nbsp:.

        filetype indent on
        set smartindent
        set shiftround

        set smartcase
        set showmatch

        autocmd BufWritePre * :%s/\\s\\+$//e

        let mapleader="\<Space>"
        let maplocalleader="\<space>"

        ino jk <esc>
        ino kj <esc>
        cno jk <c-c>
        cno kj <c-c>
        tno jk <c-\><c-n>
        tno kj <c-\><c-n>
        vno jk <esc>
        vno kj <esc>

        nnoremap J :tabprevious<CR>
        nnoremap K :tabnext<CR>
      '';
      plugins = with pkgs.vimPlugins; [
        vim-repeat
        # nnn-vim
        vim-fugitive
        popup-nvim
        plenary-nvim
        nvim-web-devicons
        bufexplorer
        undotree
        lexima-vim
        vim-vsnip-integ
        friendly-snippets
        {
          plugin = indentLine;
          type = "lua";
          config = ''
            vim.g.indentLine_char = '┆'
            vim.g.indentLine_color_term = 239
          '';
        }
        {
          plugin = vim-vsnip;
          type = "lua";
          config = "";
        }
        {
          plugin = vim-move;
          type = "lua";
          config = ''
            vim.g.move_key_modifier = "C"
          '';
        }
        {
          plugin = suda-vim;
          type = "lua";
          config = ''
            vim.g.move_key_modifier = "C"
          '';
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
          plugin = vim-easymotion;
          type = "lua";
          config = ''
            vim.g.EasyMotion_do_mapping = false
            vim.g.EasyMotion_smartcase = true

            vim.keymap.set("n", ",", "<Plug>(easymotion-overwin-f2)", {})
          '';
        }
        {
          plugin = lualine-nvim;
          type = "lua";
          config = ''
            require('lualine').setup{
              options = {
                theme = "auto",
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
          plugin = fern-vim;
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
            vim.api.nvim_set_option("timeoutlen", 500)

            require('which-key').register({
              {
                name = "+general",
                ["<leader>"] = { ":Telescope find_files<CR>", "find-files" },
                ["/"] = { ":Telescope live_grep<CR>", "telescope-grep" },
                r = { ":noh<CR>", "highlights-remove" },
                h = { "<C-w>h", "window-left" },
                j = { "<C-w>j", "window-below" },
                k = { "<C-w>k", "window-above" },
                l = { "<C-w>l", "window-right" },
                s = { "<C-w>s", "window-split-below" },
                v = { "<C-w>v", "window-split-right" },
                q = { ":q<CR>", "file-quit" },
                Q = { ":qall<CR>", "file-quit-all" },
                w = { ":w<CR>", "file-save" },
                n = { ":tabnew<CR>", "tab-new" },
                u = { ":UndotreeToggle<CR>", "undotree-toggle" },
                t = { ":terminal<CR>", "terminal-open" },
                --- f = { ":NnnPicker %:p:h<CR>", "nnn-open" }
              },
              g = {
                name = "+git",
                s = { ":Git<CR>", "git-status" },
                b = { ":Git blame<CR>", "git-blame" },
                d = { ":Gdiff<CR>", "git-diff" },
                p = { ":Git push<CR>", "git-push" },
                l = { ":Git pull<CR>", "git-pull" },
                f = { ":Git fetch<CR>", "git-pull" },
                a = { ":Git add *<CR>", "git-add-all" },
                c = { ":Git commit --verbose<CR>", "git-commit-verbose" },
                e = { ":GitMessenger<CR>", "git-messenger" }
              },
              p = {
                name = "+telescope",
                f = { ":Telescope find_files<CR>", "telescope-files" },
                g = { ":GFiles<CR>", "telescope-git-files" },
                b = { ":Telescope buffers<CR>", "telescope-buffers" },
                l = { ":Colors<CR>", "telescope-colors" },
                r = { ":Telescope live_grep<CR>", "telescope-grep" },
                g = { ":Telescope git_commits<CR>", "telescope-commits" },
                s = { ":Snippets<CR>", "telescope-snippets" },
                m = { ":Telescope commands<CR>", "telescope-commands" },
                h = { ":Telescope man_pages<CR>", "telescope-man-pages" },
                t = { ":Telescope treesitter<CR>", "telescope-treesitter" }
              },
              b = {
                name = "+bufexplorer",
                i = "bufexplorer-open",
                t = "bufexplorer-toggle",
                s = "bufexplorer-horizontal-split",
                v = "bufexplorer-vertical-split"
              }
            }, { prefix = "<leader>" })
          '';
        }
      ];
    };
  };
}
