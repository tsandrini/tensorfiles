# --- modules/editors/neovim.nix
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

{ config, options, pkgs, lib, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;
    withNodeJs = true;
    plugins = with pkgs.vimPlugins; [
      vim-repeat
      nvim-web-devicons
      nnn-vim
      vim-fugitive
      {
        plugin = indentLine;
        type = "lua";
        config = ''
          vim.g.indentLine_char = '┆'
          vim.g.indentLine_color_term = 239
        '';
      }
      lexima-vim
      {
        plugin = vim-vsnip;
        type = "lua";
        config = ''
        '';
      }
      vim-vsnip-integ
      friendly-snippets
      {
        plugin = vim-move;
        type = "lua";
        config = ''
          vim.g.move_key_modifier = "C"
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

          vim.keymap.set(
            "n",
            "m",
            ":Fern . -drawer -reveal=% -width=35 <CR><C-w>=",
            {noremap=true, silent=true}
          )

          vim.keymap.set(
            "n",
            "<Plug>(fern-close-drawer)",
            ":<C-u>FernDo close -drawer -stay<CR>",
            {noremap=true, silent=true}
          )

          local function fern_init()
            local opts = {silent=true, buffer=0}
            vim.keymap.set("n", "<Plug>(fern-action-open)",
              "<Plug>(fern-action-open:select)", opts)

            vim.api.nvim_buf_set_keymap(
              0,
              "n",
              "<Plug>(fern-action-custom-open-expand-collapse)",
              "fern#smart#leaf('<plug>(fern-action-open)<plug>(fern-close-drawer)', '<plug>(fern-action-expand)', '<plug>(fern-action-collapse)')",
              {silent=true, expr=true}
            )
            vim.keymap.set("n", "q", ":<C-u>quit<CR>", opts)
            vim.keymap.set("n", "n", "<Plug>(fern-action-new-path)", opts)
            vim.keymap.set("n", "d", "<Plug>(fern-action-remove)", opts)
            vim.keymap.set("n", "m", "<Plug>(fern-action-move)", opts)
            vim.keymap.set("n", "r", "<Plug>(fern-action-rename)", opts)
            vim.keymap.set("n", "R", "<Plug>(fern-action-reload)", opts)
            vim.keymap.set("n", "<C-h>", "<Plug>(fern-action-hidden-toggle)", opts)
            vim.keymap.set("n", "l", "<Plug>(fern-action-custom-open-expand-collapse)", opts)
            vim.keymap.set("n", "h", "<Plug>(fern-action-collapse)", opts)
            vim.keymap.set("n", "<2-LeftMouse>", "<Plug>(fern-action-custom-open-expand-collapse)", opts)
            vim.keymap.set("n", "<CR>", "<Plug>(fern-action-custom-open-expand-collapse)", opts)
          end

          local group = vim.api.nvim_create_augroup("fern_group", {clear=true})
          vim.api.nvim_create_autocmd("FileType", {
            pattern="fern",
            callback=fern_init,
            group=group
          })
        '';
      }
      popup-nvim
      plenary-nvim
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
      bufexplorer
      undotree
      {
        plugin = which-key-nvim;
        type = "lua";
        config = ''
          vim.api.nvim_set_option("timeoutlen", 500)

          require('which-key').register({
            {
              name = "+general",
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
              f = { ":NnnPicker %:p:h<CR>", "nnn-open" }
            }
          }, { prefix = "b" })
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
    ];
  };
}
